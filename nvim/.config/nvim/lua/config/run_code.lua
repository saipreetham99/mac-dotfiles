-- Run the current C++, Java, or Python file in the SAME bottom Snacks
-- terminal opened by LazyVim's Ctrl+/ (Ctrl+_ in some terminals).
local M = {}

local last_source_buffer

local supported = { cpp = true, java = true, python = true }

function M.is_supported()
  return supported[vim.bo.filetype] == true
end

-- Resolve the actual Java entry point, not the filename. This matters for
-- standalone exercises such as "20StreamAPI.java" containing "class StreamAPI".
-- Tokenize enough Java to ignore comments and string/character/text literals,
-- and recognize which class/interface/record owns a main(String[]) method.
local function java_tokens(source)
  local tokens = {}
  local i, n = 1, #source
  while i <= n do
    local c, next_char = source:sub(i, i), source:sub(i + 1, i + 1)
    if c == "/" and next_char == "/" then
      local e = source:find("\n", i + 2, true)
      i = e or (n + 1)
    elseif c == "/" and next_char == "*" then
      local e = source:find("*/", i + 2, true)
      i = e and (e + 2) or (n + 1)
    elseif c == '"' or c == "'" then
      local quote = c
      local triple = c == '"' and source:sub(i, i + 2) == '"""'
      i = i + (triple and 3 or 1)
      while i <= n do
        if source:sub(i, i) == "\\" then
          i = i + 2
        elseif triple and source:sub(i, i + 2) == '"""' then
          i = i + 3
          break
        elseif not triple and source:sub(i, i) == quote then
          i = i + 1
          break
        else
          i = i + 1
        end
      end
    elseif c:match("[%a_$]") then
      local _, e = source:find("^[%a_$][%w_$]*", i)
      tokens[#tokens + 1] = source:sub(i, e)
      i = e + 1
    elseif not c:match("%s") then
      tokens[#tokens + 1] = c
      i = i + 1
    else
      i = i + 1
    end
  end
  return tokens
end

local function java_main_class(file)
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok then
    return nil, "Run Code: cannot read Java source: " .. file
  end

  local tokens = java_tokens(table.concat(lines, "\n"))
  local package_name, classes, scopes = "", {}, {}
  local pending_type, declaration_start = nil, 1

  local function containing_class()
    local names = {}
    for _, scope in ipairs(scopes) do
      if scope ~= "" then
        names[#names + 1] = scope
      end
    end
    return #names > 0 and table.concat(names, "$") or nil
  end

  for i, tok in ipairs(tokens) do
    if tok == "package" and package_name == "" and #scopes == 0 then
      local parts, j = {}, i + 1
      while tokens[j] and tokens[j] ~= ";" do
        parts[#parts + 1] = tokens[j]
        j = j + 1
      end
      package_name = table.concat(parts)
    elseif (tok == "class" or tok == "interface" or tok == "record" or tok == "enum")
      and tokens[i - 1] ~= "." and tokens[i + 1] and tokens[i + 1]:match("^[%a_$][%w_$]*$") then
      pending_type = tokens[i + 1]
    elseif tok == "{" then
      -- false values can't be appended through table.insert/ipairs: use an
      -- explicit marker for non-type blocks (methods, anonymous classes).
      scopes[#scopes + 1] = pending_type or ""
      pending_type = nil
      declaration_start = i + 1
    elseif tok == "}" then
      scopes[#scopes] = nil
      pending_type = nil
      declaration_start = i + 1
    elseif tok == ";" then
      declaration_start = i + 1
    elseif tok == "main" and tokens[i + 1] == "(" and scopes[#scopes] ~= nil and scopes[#scopes] ~= "" then
      local has_public, has_static, has_void = false, false, false
      for j = declaration_start, i - 1 do
        has_public = has_public or tokens[j] == "public"
        has_static = has_static or tokens[j] == "static"
        has_void = has_void or tokens[j] == "void"
      end
      local has_string, has_array, j = false, false, i + 2
      while tokens[j] and tokens[j] ~= ")" and tokens[j] ~= "{" and tokens[j] ~= ";" do
        has_string = has_string or tokens[j] == "String"
        has_array = has_array or tokens[j] == "[" or (tokens[j] == "." and tokens[j + 1] == "." and tokens[j + 2] == ".")
        j = j + 1
      end
      if has_public and has_static and has_void and has_string and has_array then
        local name = containing_class()
        if name then
          classes[#classes + 1] = name
        end
      end
    end
  end

  if #classes == 0 then
    return nil, "Run Code: no public static void main(String[] args) found in this Java file"
  end
  -- If several classes declare main(), prefer the one matching the file's
  -- basename; otherwise use the first runnable class in source order.
  local basename = vim.fn.fnamemodify(file, ":t:r")
  local selected = classes[1]
  for _, name in ipairs(classes) do
    if name == basename then
      selected = name
      break
    end
  end
  return (package_name ~= "" and (package_name .. ".") or "") .. selected
end

local function runner_command(file, filetype)
  local quote = vim.fn.shellescape
  local dir = vim.fn.fnamemodify(file, ":h")
  local prefix = "cd " .. quote(dir) .. " && "

  if filetype == "cpp" then
    local compiler = vim.fn.executable("clang++") == 1 and "clang++" or "g++"
    if vim.fn.executable(compiler) == 0 then
      return nil, "Run Code: install clang++ or g++ to run C++ files"
    end

    -- Do not litter the source folder with executables. Each source file
    -- gets its own stable binary name under Neovim's cache directory.
    local build_dir = vim.fn.stdpath("cache") .. "/run-code"
    local ok = pcall(vim.fn.mkdir, build_dir, "p")
    if not ok or vim.fn.isdirectory(build_dir) == 0 then
      return nil, "Run Code: cannot create " .. build_dir
    end
    local binary = build_dir .. "/" .. vim.fn.sha256(file):sub(1, 16)
    return prefix .. compiler .. " -std=c++20 -Wall -Wextra " .. quote(file) .. " -o " .. quote(binary) .. " && " .. quote(binary)
  end

  if filetype == "java" then
    if vim.fn.executable("java") == 0 or vim.fn.executable("javac") == 0 then
      return nil, "Run Code: install a JDK and put java and javac on PATH"
    end

    -- A Java filename does not necessarily name its entry class. In practice
    -- exercises often have filenames like 20StreamAPI.java -> class StreamAPI.
    local main_class, main_error = java_main_class(file)
    if not main_class then
      return nil, main_error
    end

    -- Store compiled classes in Neovim's cache, not the source folder.
    local build_dir = vim.fn.stdpath("cache") .. "/run-code/java/" .. vim.fn.sha256(file):sub(1, 16)
    local ok = pcall(vim.fn.mkdir, build_dir, "p")
    if not ok or vim.fn.isdirectory(build_dir) == 0 then
      return nil, "Run Code: cannot create " .. build_dir
    end

    local classpath = build_dir .. (vim.fn.has("win32") == 1 and ";" or ":") .. dir
    return prefix
      .. "javac -d " .. quote(build_dir) .. " -cp " .. quote(classpath) .. " " .. quote(file)
      .. " && java -cp " .. quote(classpath) .. " " .. quote(main_class)
  end

  if filetype == "python" then
    if vim.fn.executable("python3") == 0 then
      return nil, "Run Code: python3 was not found on PATH"
    end
    return prefix .. "python3 -u " .. quote(file)
  end

  return nil, "Run Code: supported filetypes are C++, Java, and Python"
end

function M.run()
  local current = vim.api.nvim_get_current_buf()
  local bufnr = current

  -- Re-run the last source file when called from the Snacks terminal.
  if vim.bo[current].buftype == "terminal" then
    bufnr = last_source_buffer
  end

  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify("Run Code: open a C++, Java, or Python source file first", vim.log.levels.WARN)
    return
  end

  local filetype = vim.bo[bufnr].filetype
  if not supported[filetype] then
    vim.notify("Run Code: supported filetypes are C++, Java, and Python", vim.log.levels.WARN)
    return
  end

  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    vim.notify("Run Code: save this file with a filename first", vim.log.levels.WARN)
    return
  end

  -- Save source first. If saving fails, do not silently execute old code.
  if vim.bo[bufnr].modified or vim.fn.filereadable(file) == 0 then
    local ok, err = pcall(function()
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("silent write")
      end)
    end)
    if not ok then
      vim.notify("Run Code: could not save the file: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
  end

  local command, err = runner_command(file, filetype)
  if not command then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  -- Match LazyVim's Ctrl+/ mapping exactly: it uses Snacks.terminal with
  -- `cwd = LazyVim.root()` and the default terminal number 1. Resolve the
  -- root while the source buffer is current, even if Run was pressed in
  -- terminal Normal mode to re-run the previous source file.
  local root = vim.api.nvim_buf_call(bufnr, function()
    return LazyVim.root()
  end)

  if not Snacks or not Snacks.terminal then
    vim.notify("Run Code: LazyVim's Snacks terminal is unavailable", vim.log.levels.ERROR)
    return
  end

  -- `get` opens the terminal if necessary but NEVER toggles/hides an
  -- already-visible terminal. Both Run and Ctrl+/ now use the same shell.
  local term, created = Snacks.terminal.get(nil, { cwd = root, count = 1 })
  if not term or not vim.api.nvim_buf_is_valid(term.buf) then
    vim.notify("Run Code: could not open the Ctrl+/ terminal", vim.log.levels.ERROR)
    return
  end
  if not created then
    term:show()
    term:focus()
  end

  -- Neovim stores the shell's job channel on terminal buffers. Snacks.win
  -- does not implement toggleterm's :send(), so send to the existing pty.
  local channel = vim.b[term.buf].terminal_job_id
  if not channel or channel <= 0 then
    vim.notify("Run Code: terminal shell is not running", vim.log.levels.ERROR)
    return
  end

  last_source_buffer = bufnr

  local function send_command()
    if vim.api.nvim_buf_is_valid(term.buf) and vim.b[term.buf].terminal_job_id == channel then
      vim.api.nvim_chan_send(channel, command .. "\n")
    end
  end

  if created then
    send_command()
  else
    -- Interrupt any earlier interactive program before issuing a new run.
    -- A brief delay avoids sending the command to the old process before
    -- the shell regains control of the terminal.
    vim.api.nvim_chan_send(channel, "\003")
    vim.defer_fn(send_command, 100)
  end
end

return M
