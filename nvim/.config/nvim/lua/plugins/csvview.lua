return {
  "hat0uma/csvview.nvim",
  ft = { "csv", "tsv" },
  opts = {
    view = { display_mode = "border" }, -- "highlight" for no column lines
  },
  config = function(_, opts)
    require("csvview").setup(opts)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "csv", "tsv" },
      callback = function()
        vim.cmd("CsvViewEnable")
      end,
    })
    if vim.bo.filetype == "csv" or vim.bo.filetype == "tsv" then
      vim.cmd("CsvViewEnable")
    end
  end,
}
