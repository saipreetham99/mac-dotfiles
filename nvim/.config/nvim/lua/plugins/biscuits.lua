return {
  {
    "code-biscuits/nvim-biscuits",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      -- shows automatically on every buffer -- no manual attach needed
      show_on_start = true,
      -- bail out on huge files rather than slow things down
      max_file_size = "100kb",
    },
    keys = {
      {
        "<leader>ub",
        function()
          require("nvim-biscuits").toggle_biscuits()
        end,
        desc = "Toggle Biscuits",
      },
    },
  },
}
