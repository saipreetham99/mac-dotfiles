return {
  {
    "3rd/image.nvim",
    event = "VeryLazy",
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        markdown = { enabled = true },
        ["oil.nvim"] = { enabled = true },
      },
      max_width = 100,
      max_height = 30,
    },
  },
  {
    "akinsho/toggleterm.nvim",
    opts = {
      direction = "float",
      float_opts = { border = "curved" },
    },
  },
  -- make sure oil.nvim is present
  {
    "stevearc/oil.nvim",
    opts = {},
  },
}
