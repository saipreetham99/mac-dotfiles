-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Never auto-format backup files (*.bak, *~, *.orig). Neovim's filetype
-- detection strips these suffixes and matches on whatever's underneath
-- (e.g. GameStoreContextModelSnapshot.cs.bak -> filetype "cs"), so
-- without this a huge auto-generated file like an EF migrations
-- snapshot can get silently picked up by format-on-save and have its
-- formatter (csharpier, stylua, etc.) choke on it.
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("no_format_backup_files", { clear = true }),
  pattern = { "*.bak", "*~", "*.orig" },
  callback = function(ev)
    vim.b[ev.buf].autoformat = false
  end,
})

-- Persist whichever colorscheme is active (e.g. picked via <leader>uC)
-- so it's still applied the next time Neovim starts. Read back by
-- techbase.lua's init function.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("persist_colorscheme", { clear = true }),
  callback = function()
    local state_file = vim.fn.stdpath("state") .. "/colorscheme"
    local f = io.open(state_file, "w")
    if f then
      f:write(vim.g.colors_name or "")
      f:close()
    end
  end,
})

-- Turn on Snacks dim by default at startup. VeryLazy fires after
-- snacks.nvim's own setup has already run, so this can't race or get
-- overwritten by it. <leader>ud (see snacks-dim.lua) still toggles it
-- off/on manually.
-- vim.api.nvim_create_autocmd("User", {
--   pattern = "VeryLazy",
--   group = vim.api.nvim_create_augroup("dim_on_by_default", { clear = true }),
--   once = true,
--   callback = function()
--     Snacks.dim.enable()
--   end,
-- })
