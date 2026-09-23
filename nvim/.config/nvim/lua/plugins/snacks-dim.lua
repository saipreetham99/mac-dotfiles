-- snacks.nvim is already eager-loaded by LazyVim's defaults, so this
-- file just extends its opts (deep-merged by lazy.nvim) and adds a
-- toggle keymap -- no new plugin, no lazy-loading concerns.
--
-- Enabled on by default via the VeryLazy autocmd in autocmds.lua.
-- <leader>ud below just lets you flip it off/back on manually.
return {
  {
    "folke/snacks.nvim",
    opts = {
      dim = {},
    },
    keys = {
      {
        "<leader>ud",
        function()
          Snacks.dim()
        end,
        desc = "Toggle Dim",
      },
    },
  },
}
