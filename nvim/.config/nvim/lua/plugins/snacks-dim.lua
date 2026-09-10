-- snacks.nvim is already eager-loaded by LazyVim's defaults, so this
-- file just extends its opts (deep-merged by lazy.nvim) and adds a
-- toggle keymap -- no new plugin, no lazy-loading concerns.
return {
  {
    "folke/snacks.nvim",
    opts = {
      dim = {}, -- accept defaults; activated on demand via Snacks.dim()
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
