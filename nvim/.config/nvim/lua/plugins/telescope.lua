return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  opts = function(_, opts)
    local actions = require("telescope.actions")
    opts.defaults = opts.defaults or {}
    opts.defaults.mappings = opts.defaults.mappings or {}
    opts.defaults.mappings.i = opts.defaults.mappings.i or {}
    opts.defaults.mappings.n = opts.defaults.mappings.n or {}
    opts.defaults.mappings.i["<C-s>"] = actions.select_horizontal
    opts.defaults.mappings.i["<C-v>"] = actions.select_vertical
    opts.defaults.mappings.n["<C-s>"] = actions.select_horizontal
    opts.defaults.mappings.n["<C-v>"] = actions.select_vertical
    opts.defaults.preview = opts.defaults.preview or {}
    opts.defaults.preview.treesitter = false
    return opts
  end,
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    pcall(telescope.load_extension, "fzf")
  end,
}
