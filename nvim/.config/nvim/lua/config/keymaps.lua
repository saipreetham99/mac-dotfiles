-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- vim.keymap.set("n", "<leader>y", '"+y', { desc = "Yank to clipboard" }) -- normal mode copy
-- vim.keymap.set("v", "<leader>y", '"+y', { desc = "Yank to clipboard" }) -- visual mode copy
--
-- vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste from clipboard" })
-- vim.keymap.set("v", "<leader>p", '"+p', { desc = "Paste from clipboard" })
-- Custom save commands (safe: doesn't mess with built-in :e)

-- Disable arrow keys in normal mode
vim.keymap.set("n", "<Up>", "<Nop>", { noremap = true, silent = true })
vim.keymap.set("n", "<Down>", "<Nop>", { noremap = true, silent = true })
vim.keymap.set("n", "<Left>", "<Nop>", { noremap = true, silent = true })
vim.keymap.set("n", "<Right>", "<Nop>", { noremap = true, silent = true })

-- Disable auto-comment insertion when pressing `o` on the last line only
vim.keymap.set("n", "o", function()
  local current_line = vim.fn.line(".")
  local last_line = vim.fn.line("$")

  if current_line == last_line then
    local saved_fo = vim.bo.formatoptions
    vim.bo.formatoptions = saved_fo:gsub("o", "")

    local keys = vim.api.nvim_replace_termcodes("o", true, false, true)
    vim.api.nvim_feedkeys(keys, "n", false)

    -- Restore after the keypress is processed
    vim.schedule(function()
      vim.bo.formatoptions = saved_fo
    end)
  else
    local keys = vim.api.nvim_replace_termcodes("o", true, false, true)
    vim.api.nvim_feedkeys(keys, "n", false)
  end
end, { noremap = true, desc = "Open line below (no auto-comment on last line)" })

vim.keymap.set("n", "<leader>mv", function()
  local ok, oil = pcall(require, "oil")
  local file
  if ok and vim.bo.filetype == "oil" then
    local entry = oil.get_cursor_entry()
    file = oil.get_current_dir() .. entry.name
  else
    file = vim.fn.expand("<cfile>")
  end
  if not file or file == "" then
    file = vim.fn.input("Video path: ")
  end
  local Terminal = require("toggleterm.terminal").Terminal
  local mpv = Terminal:new({ cmd = "mpv --no-terminal '" .. file .. "'", direction = "float", close_on_exit = true })
  mpv:toggle()
end, { desc = "Play video (mpv float)" })

local function quick_preview()
  local ok, oil = pcall(require, "oil")
  local file
  if ok and vim.bo.filetype == "oil" then
    local entry = oil.get_cursor_entry()
    if not entry then
      return
    end
    file = oil.get_current_dir() .. entry.name
  else
    file = vim.fn.expand("<cfile>")
  end
  if not file or file == "" then
    return
  end

  local ext = (file:match("^.+%.(.+)$") or ""):lower()
  local image_ext = { png = true, jpg = true, jpeg = true, gif = true, webp = true, bmp = true }
  local video_ext = { mp4 = true, mkv = true, mov = true, webm = true, avi = true }

  if image_ext[ext] then
    local buf = vim.api.nvim_create_buf(false, true)
    local w, h = math.floor(vim.o.columns * 0.6), math.floor(vim.o.lines * 0.6)
    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = w,
      height = h,
      row = math.floor((vim.o.lines - h) / 2),
      col = math.floor((vim.o.columns - w) / 2),
      border = "rounded",
      style = "minimal",
    })
    vim.keymap.set("n", "q", function()
      pcall(vim.api.nvim_win_close, win, true)
    end, { buffer = buf })

    local image = require("image")
    local img = image.from_file(file, { window = win, buffer = buf, x = 0, y = 0, width = w, height = h })
    img:render()
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(win),
      once = true,
      callback = function()
        pcall(img.clear, img)
      end,
    })
  elseif video_ext[ext] then
    local Terminal = require("toggleterm.terminal").Terminal
    Terminal:new({
      cmd = "mpv --no-terminal --loop --mute '" .. file .. "'",
      direction = "float",
      close_on_exit = true,
    }):toggle()
  else
    vim.notify("No preview for this file type", vim.log.levels.WARN)
  end
end

vim.keymap.set("n", "<leader>p", quick_preview, { desc = "Quick Look preview" })
vim.keymap.set("n", "q:", "<nop>", { silent = true })
vim.api.nvim_create_user_command("Wq", "wq", {})
