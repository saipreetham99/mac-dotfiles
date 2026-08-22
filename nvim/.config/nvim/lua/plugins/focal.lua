-- Neovim's default updatetime (4000ms) means hover previews take 4s to
-- appear. focal.nvim's hover is driven by CursorHold, so this is what
-- actually makes it feel responsive.
vim.o.updatetime = 300

return {
  {
    "hmdfrds/focal.nvim",
    event = "VeryLazy",
    dependencies = { "3rd/image.nvim" },
    opts = {
      backend = "image.nvim",
      -- 1.5x the plugin's defaults (80/40 cells, 50/50%)
      max_width = 120,
      max_height = 60,
      max_width_percent = 75,
      max_height_percent = 75,
    },
  },
}
