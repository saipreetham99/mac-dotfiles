-- Neovim sets .xsl / .xslt files to filetype "xslt"; reuse the XML
-- treesitter parser for highlighting and indentation there too
vim.treesitter.language.register("xml", "xslt")

local xml_fts = { "xml", "xsd", "xsl", "xslt", "svg" }

-- Format with lemminx on every save, instead of going through
-- LazyVim's autoformat (which wasn't picking it up for these files)
vim.api.nvim_create_autocmd("FileType", {
  pattern = xml_fts,
  callback = function(ev)
    vim.b[ev.buf].autoformat = false -- avoid LazyVim formatting twice
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = ev.buf,
      callback = function()
        vim.lsp.buf.format({ bufnr = ev.buf, name = "lemminx", timeout_ms = 3000 })
      end,
    })
  end,
})

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lemminx = {
          filetypes = xml_fts,
          settings = {
            xml = { format = { enabled = true } },
          },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "xml" } },
  },
}
