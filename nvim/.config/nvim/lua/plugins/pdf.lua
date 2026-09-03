-- Inline PDF viewer.
--
-- Renders the current page as a PNG (pdftoppm) and draws it with
-- image.nvim, so it works the same whether the file is opened from
-- the terminal (`nvim foo.pdf`) or picked in oil.
--
-- pdfinfo/pdftoppm both run async (vim.system), so nothing blocks
-- input while a page is being rasterised.
--
-- Requires: brew install poppler   (for pdftoppm + pdfinfo)

local DEBOUNCE_MS = 250
local DPI = "200"

local state = {} -- bufnr -> { file, page, pages, img, dir, timer, gen }

----------------------------------------------------------------------
-- drawing (fast, synchronous)
----------------------------------------------------------------------

local function draw(bufnr, png)
  local s = state[bufnr]
  if not s then
    return
  end
  local win = vim.fn.bufwinid(bufnr)
  if win == -1 then
    return
  end

  local height = vim.api.nvim_win_get_height(win)
  local lines = {
    string.format(" %s  —  page %d/%d   ]p next   [p prev", vim.fn.fnamemodify(s.file, ":t"), s.page, s.pages or 1),
  }
  for _ = 2, math.max(height, 2) do
    table.insert(lines, "")
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  if s.img then
    s.img:clear()
    s.img = nil
  end

  local ok, image = pcall(require, "image")
  if not ok then
    vim.notify("pdf: image.nvim not available", vim.log.levels.WARN)
    return
  end

  -- image.nvim defaults max_height_window_percentage to 50, which is what
  -- squashes a full page down to half the window; lift it and cap by hand
  -- so the page fills everything below the header line
  local img = image.from_file(png, {
    window = win,
    buffer = bufnr,
    x = 0,
    y = 1,
    max_height = math.max(height - 1, 1),
    max_width_window_percentage = 100,
    max_height_window_percentage = 100,
  })
  if img then
    img:render()
    s.img = img
  end
end

----------------------------------------------------------------------
-- async page production
----------------------------------------------------------------------

local function ensure_pages(s, cb)
  if s.pages then
    return cb()
  end
  vim.system(
    { "pdfinfo", s.file },
    { text = true },
    vim.schedule_wrap(function(res)
      local n = res.stdout and res.stdout:match("Pages:%s+(%d+)")
      s.pages = tonumber(n) or 1
      cb()
    end)
  )
end

local function ensure_png(s, page, cb)
  local prefix = s.dir .. "/p" .. page
  local png = prefix .. ".png"
  if vim.fn.filereadable(png) == 1 then
    return cb(png)
  end
  vim.system(
    {
      "pdftoppm",
      "-png",
      "-r",
      DPI,
      "-f",
      tostring(page),
      "-l",
      tostring(page),
      "-singlefile",
      s.file,
      prefix,
    },
    {},
    vim.schedule_wrap(function(res)
      if res.code == 0 and vim.fn.filereadable(png) == 1 then
        cb(png)
      end
    end)
  )
end

local function render(bufnr)
  local s = state[bufnr]
  if not s then
    return
  end
  if vim.fn.bufwinid(bufnr) == -1 then
    return
  end

  -- bump a generation counter so results from a page we've already
  -- scrolled past get thrown away instead of drawn
  local gen = (s.gen or 0) + 1
  s.gen = gen
  local page = s.page

  local function stale()
    return state[bufnr] ~= s or s.gen ~= gen or vim.fn.bufwinid(bufnr) == -1
  end

  ensure_pages(s, function()
    if stale() then
      return
    end
    ensure_png(s, page, function(png)
      if stale() then
        return
      end
      draw(bufnr, png)
    end)
  end)
end

----------------------------------------------------------------------
-- debounce (avoids spawning a process per cursor move in oil)
----------------------------------------------------------------------

local function stop_timer(s)
  if s and s.timer then
    s.timer:stop()
    if not s.timer:is_closing() then
      s.timer:close()
    end
    s.timer = nil
  end
end

local function schedule_render(bufnr, delay)
  local s = state[bufnr]
  if not s then
    return
  end
  stop_timer(s)

  if delay == 0 then
    render(bufnr)
    return
  end

  local timer = vim.uv.new_timer()
  s.timer = timer
  timer:start(
    delay,
    0,
    vim.schedule_wrap(function()
      if s.timer == timer then
        stop_timer(s)
      end
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      render(bufnr)
    end)
  )
end

----------------------------------------------------------------------

local function open(bufnr, file)
  if vim.fn.executable("pdftoppm") == 0 or vim.fn.executable("pdfinfo") == 0 then
    vim.notify("pdf: pdftoppm/pdfinfo missing — brew install poppler", vim.log.levels.ERROR)
    return
  end

  state[bufnr] = {
    file = file,
    page = 1,
    pages = nil,
    dir = vim.fn.tempname(),
    gen = 0,
  }
  vim.fn.mkdir(state[bufnr].dir, "p")

  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "pdf"

  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set("n", "]p", function()
    local s = state[bufnr]
    if s and s.pages and s.page < s.pages then
      s.page = s.page + 1
      render(bufnr)
    end
  end, vim.tbl_extend("force", opts, { desc = "PDF next page" }))
  vim.keymap.set("n", "[p", function()
    local s = state[bufnr]
    if s and s.page > 1 then
      s.page = s.page - 1
      render(bufnr)
    end
  end, vim.tbl_extend("force", opts, { desc = "PDF prev page" }))
  vim.keymap.set("n", "r", function()
    render(bufnr)
  end, vim.tbl_extend("force", opts, { desc = "PDF redraw" }))

  local immediate = vim.api.nvim_get_current_buf() == bufnr
  vim.schedule(function()
    schedule_render(bufnr, immediate and 0 or DEBOUNCE_MS)
  end)
end

local group = vim.api.nvim_create_augroup("InlinePdf", { clear = true })

-- BufReadCmd takes over the load entirely, so nvim never dumps the
-- raw PDF bytes into the buffer as text
vim.api.nvim_create_autocmd("BufReadCmd", {
  group = group,
  pattern = "*.pdf",
  callback = function(ev)
    open(ev.buf, vim.fn.fnamemodify(ev.match, ":p"))
  end,
})

vim.api.nvim_create_autocmd({ "BufWinEnter", "VimResized" }, {
  group = group,
  pattern = "*.pdf",
  callback = function(ev)
    if state[ev.buf] then
      schedule_render(ev.buf, DEBOUNCE_MS)
    end
  end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
  group = group,
  pattern = "*.pdf",
  callback = function(ev)
    local s = state[ev.buf]
    if not s then
      return
    end
    stop_timer(s)
    if s.img then
      pcall(function()
        s.img:clear()
      end)
    end
    vim.fn.delete(s.dir, "rf")
    state[ev.buf] = nil
  end,
})

return {}
