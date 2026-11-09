-- TestNG / JUnit run buttons, like the gutter icons and "Run | Debug"
-- code lenses of GUI IDEs. Every @Test method, the test class and each
-- testng.xml <suite> get a ▶ gutter sign plus a clickable lens line:
--
--   ▶ Run   Debug   ⋯         (⋯ / gutter click opens the full menu)
--
-- Runs go through Maven in the Ctrl+/ terminal (same as <leader>rr), so
-- they honour pom.xml/testng.xml exactly like `mvn test`. Debugging uses
-- jdtls + nvim-dap for methods/classes, and surefire's JDWP port for
-- suites. After a Maven run the signs turn ✓ / ✗ from surefire's reports.
local M = {}

local ns = vim.api.nvim_create_namespace("test_button")
local entries = {} -- bufnr -> list of buttons placed in that buffer
local results = {} -- "pkg.Class" -> { [method] = "PASS" | "FAIL" | "SKIP" }
local last -- { label, fn } of the last test action, for "Rerun last"
local watch_gen = 0

local labels = { run = " ▶ Run ", debug = "  Debug ", more = " ⋯ " }
local status_sign = {
  PASS = { "✓", "TestPassSign", "passed" },
  FAIL = { "✗", "TestFailSign", "failed" },
  SKIP = { "⊘", "TestSkipSign", "skipped" },
}

local function set_highlights()
  vim.api.nvim_set_hl(0, "TestSign", { fg = "#9ece6a", bold = true })
  vim.api.nvim_set_hl(0, "TestPassSign", { fg = "#9ece6a", bold = true })
  vim.api.nvim_set_hl(0, "TestFailSign", { fg = "#f7768e", bold = true })
  vim.api.nvim_set_hl(0, "TestSkipSign", { fg = "#e0af68", bold = true })
  vim.api.nvim_set_hl(0, "TestRunButton", { fg = "#1a1b26", bg = "#9ece6a", bold = true })
  vim.api.nvim_set_hl(0, "TestDebugButton", { fg = "#1a1b26", bg = "#ff9e64", bold = true })
  vim.api.nvim_set_hl(0, "TestMoreButton", { fg = "#1a1b26", bg = "#7aa2f7", bold = true })
end

---------------------------------------------------------------------------
-- Parsing
---------------------------------------------------------------------------

local function is_comment(line)
  local t = vim.trim(line)
  return t:sub(1, 2) == "//" or t:sub(1, 1) == "*" or t:sub(1, 2) == "/*"
end

local function is_suite_file(lines)
  for i = 1, math.min(#lines, 40) do
    if lines[i]:find("<suite[%s>]") then
      return i
    end
  end
end

-- Buttons for one Java buffer: the class (if it has any @Test) and each
-- @Test method. Lines are 0-based; `lens` is where the virtual line sits
-- (above the annotations), `sign` is the declaration line.
local function parse_java(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local text = table.concat(lines, "\n")
  if not text:find("@Test", 1, true) then
    return {}
  end

  local pkg = text:match("package%s+([%w_.]+)%s*;")
  local basename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t:r")
  local class_name, class_line
  for i, line in ipairs(lines) do
    local name = not is_comment(line) and line:match("^%s*[%w%s]*%f[%w]class%s+([%a_$][%w_$]*)")
    if name and (not class_name or name == basename) then
      class_name, class_line = name, i - 1
      if name == basename then
        break
      end
    end
  end
  if not class_name then
    return {}
  end
  local fqcn = (pkg and (pkg .. ".") or "") .. class_name

  local list = {}
  local has_tests = false
  for i, line in ipairs(lines) do
    if not is_comment(line) and vim.trim(line):find("^@Test%f[^%w_]") then
      for j = i, math.min(i + 15, #lines) do
        local cleaned = lines[j]:gsub("@[%w_.]+%s*%b()", ""):gsub("@[%w_.]+", "")
        if cleaned:find("%f[%w]class%s") then
          has_tests = true -- class-level @Test: the class button covers it
          break
        end
        local name = cleaned:match("([%a_$][%w_$]*)%s*%(")
        if name then
          has_tests = true
          list[#list + 1] = {
            kind = "method",
            fqcn = fqcn,
            class_name = class_name,
            method = name,
            lens = i - 1,
            sign = j - 1,
            indent = vim.fn.strdisplaywidth(line:match("^%s*")),
          }
          break
        end
      end
    end
  end
  if not has_tests then
    return {}
  end

  table.insert(list, 1, {
    kind = "class",
    fqcn = fqcn,
    class_name = class_name,
    lens = class_line,
    sign = class_line,
    indent = vim.fn.strdisplaywidth(lines[class_line + 1]:match("^%s*")),
  })
  return list
end

local function parse_suite(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local line = is_suite_file(lines)
  if not line then
    return {}
  end
  return {
    {
      kind = "suite",
      path = vim.api.nvim_buf_get_name(bufnr),
      name = lines[line]:match('name%s*=%s*"([^"]*)"') or "suite",
      lens = line - 1,
      sign = line - 1,
      indent = vim.fn.strdisplaywidth(lines[line]:match("^%s*")),
    },
  }
end

---------------------------------------------------------------------------
-- Results from surefire reports
---------------------------------------------------------------------------

local function status_of(entry)
  local class = results[entry.fqcn]
  if entry.kind == "method" then
    return class and class[entry.method]
  elseif entry.kind == "class" and class then
    local status
    for _, s in pairs(class) do
      if s == "FAIL" then
        return "FAIL"
      end
      status = (status == nil or status == "PASS") and s or status
    end
    return status
  end
end

-- TEST-*.xml is written for both TestNG and JUnit runs. Only read the
-- files the run just produced; stale ones belong to earlier runs.
local function load_results(root, since)
  for _, file in ipairs(vim.fn.glob(root .. "/target/surefire-reports/TEST-*.xml", false, true)) do
    local stat = vim.uv.fs_stat(file)
    if stat and stat.mtime.sec >= since then
      local ok, lines = pcall(vim.fn.readfile, file)
      local xml = ok and table.concat(lines, "\n") or ""
      local pos = 1
      while true do
        local s, e, attrs, closed = xml:find("<testcase%s([^>]-)(/?)>", pos)
        if not s then
          break
        end
        local body = ""
        if closed == "" then
          local close = xml:find("</testcase>", e, true)
          body = xml:sub(e + 1, close and close - 1 or #xml)
          e = close or e
        end
        local name, class = attrs:match('name="([^"]*)"'), attrs:match('classname="([^"]*)"')
        if name and class then
          local status = "PASS"
          if body:find("<failure") or body:find("<error") then
            status = "FAIL"
          elseif body:find("<skipped") then
            status = "SKIP"
          end
          results[class] = results[class] or {}
          results[class][name] = status
        end
        pos = e + 1
      end
    end
  end
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------

function M.refresh(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local ft = vim.bo[bufnr].filetype
  local list = ft == "java" and parse_java(bufnr) or ft == "xml" and parse_suite(bufnr) or {}
  entries[bufnr] = list

  for _, entry in ipairs(list) do
    local status = status_sign[status_of(entry) or ""]
    local chunks = {
      { string.rep(" ", entry.indent), "" },
      { labels.run, "TestRunButton" },
      { " ", "" },
      { labels.debug, "TestDebugButton" },
      { " ", "" },
      { labels.more, "TestMoreButton" },
    }
    if status then
      chunks[#chunks + 1] = { "  " .. status[1] .. " " .. status[3], status[2] }
    end
    -- Display columns (1-based, inside the text area) of each button.
    local col, buttons = entry.indent + 1, {}
    for _, b in ipairs({ { "run", labels.run }, { "debug", labels.debug }, { "more", labels.more } }) do
      local width = vim.fn.strdisplaywidth(b[2])
      buttons[b[1]] = { col, col + width - 1 }
      col = col + width + 1
    end
    entry.buttons = buttons

    vim.api.nvim_buf_set_extmark(bufnr, ns, entry.lens, 0, {
      virt_lines_above = true,
      virt_lines = { chunks },
    })
    vim.api.nvim_buf_set_extmark(bufnr, ns, entry.sign, 0, {
      sign_text = status and status[1] or "▶",
      sign_hl_group = status and status[2] or "TestSign",
    })
  end
end

local function refresh_all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and entries[bufnr] then
      M.refresh(bufnr)
    end
  end
end

---------------------------------------------------------------------------
-- Running
---------------------------------------------------------------------------

local function project_root(path)
  return vim.fs.root(path, { "pom.xml" })
end

local function find_suites(root)
  local files = vim.fn.glob(root .. "/*.xml", false, true)
  vim.list_extend(files, vim.fn.glob(root .. "/src/test/resources/**/*.xml", false, true))
  return vim.tbl_filter(function(file)
    local ok, lines = pcall(vim.fn.readfile, file, "", 40)
    return ok and is_suite_file(lines) ~= nil
  end, files)
end

-- Follow the terminal output of the run just started: attach the debugger
-- once surefire's JVM listens, and pick up reports once Maven is done.
local function watch(term, root, on_listen)
  watch_gen = watch_gen + 1
  local gen, since = watch_gen, os.time() - 1
  vim.api.nvim_buf_attach(term.buf, false, {
    on_lines = function(_, buf, _, first, _, last_new)
      if gen ~= watch_gen then
        return true
      end
      for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, first, last_new, false)) do
        if on_listen and line:find("Listening for transport dt_socket", 1, true) then
          vim.schedule(on_listen)
          on_listen = nil
        elseif line:find("BUILD SUCCESS", 1, true) or line:find("BUILD FAILURE", 1, true) then
          vim.schedule(function()
            load_results(root, since)
            refresh_all()
          end)
          return true
        end
      end
    end,
  })
end

local function maven(root, args, debug)
  vim.cmd("silent! wall")
  local mvn = vim.fn.filereadable(root .. "/mvnw") == 1 and "./mvnw" or "mvn"
  local cmd = "cd " .. vim.fn.shellescape(root) .. " && " .. mvn .. " -ntp test" .. args
  if debug then
    cmd = cmd .. " -Dmaven.surefire.debug"
  end
  local term = require("config.run_code").send(cmd, root)
  if not term then
    return
  end
  watch(term, root, debug and function()
    require("dap").run({
      type = "java",
      request = "attach",
      name = "Attach to surefire",
      hostName = "127.0.0.1",
      port = 5005,
    })
  end)
end

local function has_jdtls()
  return #vim.lsp.get_clients({ name = "jdtls" }) > 0
end

local function remember(label, fn)
  last = { label = label, fn = fn }
  fn()
end

local function test_arg(entry)
  local target = entry.kind == "method" and (entry.fqcn .. "#" .. entry.method) or entry.fqcn
  return " -Dtest=" .. vim.fn.shellescape(target) .. " -Dsurefire.failIfNoSpecifiedTests=false"
end

function M.run_entry(bufnr, entry, debug)
  local root = project_root(vim.api.nvim_buf_get_name(bufnr))
  if not root then
    vim.notify("Test runner: no pom.xml above this file", vim.log.levels.WARN)
    return
  end
  local what = entry.kind == "method" and (entry.method .. "()")
    or entry.kind == "class" and entry.class_name
    or vim.fn.fnamemodify(entry.path, ":t")
  local label = (debug and "Debug " or "Run ") .. what

  remember(label, function()
    if entry.kind == "suite" then
      local path = vim.fn.shellescape(entry.path)
      maven(root, " -Dsuite=" .. path .. " -Dsurefire.suiteXmlFiles=" .. path, debug)
    elseif debug and has_jdtls() and vim.api.nvim_buf_is_valid(bufnr) then
      -- jdtls launches the test itself: breakpoints, hot reload, results.
      if entry.kind == "method" then
        require("jdtls").test_nearest_method({ bufnr = bufnr, lnum = entry.sign + 1 })
      else
        require("jdtls").test_class({ bufnr = bufnr })
      end
    else
      maven(root, test_arg(entry), debug)
    end
  end)
end

function M.run_all(bufnr)
  local root = project_root(vim.api.nvim_buf_get_name(bufnr or 0))
  if not root then
    vim.notify("Test runner: no pom.xml above this file", vim.log.levels.WARN)
    return
  end
  remember("Run all tests", function()
    maven(root, "", false)
  end)
end

function M.rerun_last()
  if not last then
    vim.notify("Test runner: nothing has been run yet", vim.log.levels.WARN)
    return
  end
  last.fn()
end

---------------------------------------------------------------------------
-- Menu + lookups
---------------------------------------------------------------------------

function M.menu(bufnr, entry)
  local items = {}
  local function add(label, fn)
    items[#items + 1] = { label = label, fn = fn }
  end

  local class_entry
  for _, e in ipairs(entries[bufnr] or {}) do
    if e.kind == "class" then
      class_entry = e
    end
  end

  if entry and entry.kind == "method" then
    add("▶ Run '" .. entry.method .. "()'", function() M.run_entry(bufnr, entry, false) end)
    add(" Debug '" .. entry.method .. "()'", function() M.run_entry(bufnr, entry, true) end)
  end
  if class_entry then
    add("▶ Run all in '" .. class_entry.class_name .. "'", function() M.run_entry(bufnr, class_entry, false) end)
    add(" Debug all in '" .. class_entry.class_name .. "'", function() M.run_entry(bufnr, class_entry, true) end)
  end

  local root = project_root(vim.api.nvim_buf_get_name(bufnr))
  for _, path in ipairs(root and find_suites(root) or {}) do
    local suite = { kind = "suite", path = path }
    local name = vim.fn.fnamemodify(path, ":.")
    add("▶ Run suite '" .. name .. "'", function() M.run_entry(bufnr, suite, false) end)
    add(" Debug suite '" .. name .. "'", function() M.run_entry(bufnr, suite, true) end)
  end
  add("▶ Run all tests (mvn test)", function() M.run_all(bufnr) end)
  if last then
    add("↻ Rerun last: " .. last.label, M.rerun_last)
  end

  vim.ui.select(items, {
    prompt = "Tests",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      choice.fn()
    end
  end)
end

-- Method whose declaration is at/above the cursor, else the class/suite.
function M.nearest(bufnr, lnum)
  local best
  for _, e in ipairs(entries[bufnr] or {}) do
    if e.kind == "method" and e.lens <= lnum and (not best or e.lens > best.lens) then
      best = e
    end
  end
  return best or (entries[bufnr] or {})[1]
end

-- Called by the global <LeftMouse> handler in run-button.lua. Returns true
-- if the click landed on a test button and was handled.
function M.click(pos)
  local bufnr = vim.fn.winbufnr(pos.winid)
  if bufnr == -1 or not entries[bufnr] or pos.line == 0 then
    return false
  end
  local wininfo = vim.fn.getwininfo(pos.winid)[1]
  local textoff = wininfo and wininfo.textoff or 0
  local text_row = vim.fn.screenpos(pos.winid, pos.line, 1).row
  local on_virt_line = text_row > 0 and pos.screenrow < text_row

  for _, entry in ipairs(entries[bufnr]) do
    if on_virt_line and pos.line == entry.lens + 1 then
      local col = pos.wincol - textoff
      for action, range in pairs(entry.buttons) do
        if col >= range[1] and col <= range[2] then
          vim.schedule(function()
            if action == "more" then
              M.menu(bufnr, entry)
            else
              M.run_entry(bufnr, entry, action == "debug")
            end
          end)
          return true
        end
      end
      return false
    elseif not on_virt_line and pos.wincol > 0 and pos.wincol <= textoff and pos.line == entry.sign + 1 then
      vim.schedule(function()
        M.menu(bufnr, entry)
      end)
      return true
    end
  end
  return false
end

---------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------

function M.setup()
  set_highlights()
  local group = vim.api.nvim_create_augroup("test_button", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_highlights })
  vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "TextChanged", "InsertLeave" }, {
    group = group,
    pattern = { "*.java", "*.xml", "java", "xml" },
    callback = function(args)
      local ft = vim.bo[args.buf].filetype
      if ft == "java" or ft == "xml" then
        M.refresh(args.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(args)
      entries[args.buf] = nil
    end,
  })
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local ft = vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype
    if ft == "java" or ft == "xml" then
      M.refresh(bufnr)
    end
  end

  local function at_cursor(fn)
    return function()
      local bufnr = vim.api.nvim_get_current_buf()
      local entry = M.nearest(bufnr, vim.api.nvim_win_get_cursor(0)[1] - 1)
      if not entry then
        vim.notify("Test runner: no @Test or <suite> in this buffer", vim.log.levels.WARN)
        return
      end
      fn(bufnr, entry)
    end
  end
  local function class_or_suite(debug)
    return at_cursor(function(bufnr)
      M.run_entry(bufnr, entries[bufnr][1], debug)
    end)
  end

  local map = function(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { desc = desc, silent = true })
  end
  map("<leader>rt", at_cursor(function(b, e) M.run_entry(b, e, false) end), "Run nearest test")
  map("<leader>rd", at_cursor(function(b, e) M.run_entry(b, e, true) end), "Debug nearest test")
  map("<leader>rc", class_or_suite(false), "Run test class / suite")
  map("<leader>rC", class_or_suite(true), "Debug test class / suite")
  map("<leader>ra", function() M.run_all(0) end, "Run all tests (mvn test)")
  map("<leader>rl", M.rerun_last, "Rerun last test")
  map("<leader>rm", function()
    local bufnr = vim.api.nvim_get_current_buf()
    M.menu(bufnr, M.nearest(bufnr, vim.api.nvim_win_get_cursor(0)[1] - 1))
  end, "Test menu")
  pcall(function()
    require("which-key").add({ { "<leader>r", group = "run / test" } })
  end)
end

return M
