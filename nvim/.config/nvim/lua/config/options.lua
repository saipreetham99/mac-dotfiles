-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Use basedpyright (community fork: stricter diagnostics on by default,
-- ships on PyPI, tracks upstream pyright within a day) instead of pyright
-- for the lang.python extra. Ruff stays as-is for linting/formatting.
vim.g.lazyvim_python_lsp = "basedpyright"
