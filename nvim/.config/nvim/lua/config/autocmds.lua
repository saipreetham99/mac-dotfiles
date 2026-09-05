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
