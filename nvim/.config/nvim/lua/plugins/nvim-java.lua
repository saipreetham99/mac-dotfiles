-- lua/plugins/nvim-java.lua

-- jdtls inlay hints sometimes point past the end of a line that changed
-- since they were computed, and nvim 0.12 errors on every redraw because
-- of it. Skip those stale hints (inlay-hint namespace only); the next
-- refresh from jdtls draws them correctly.
local hint_ns = vim.api.nvim_create_namespace("nvim.lsp.inlayhint")
local set_extmark = vim.api.nvim_buf_set_extmark
vim.api.nvim_buf_set_extmark = function(buf, ns, line, col, opts)
  if ns == hint_ns then
    local ok, id = pcall(set_extmark, buf, ns, line, col, opts)
    return ok and id or nil
  end
  return set_extmark(buf, ns, line, col, opts)
end

return {
  { "mfussenegger/nvim-jdtls", enabled = false },
  {
    "nvim-java/nvim-java",
    config = function()
      require("java").setup({
        spring_boot_tools = { enable = true },
      })
      vim.lsp.enable("jdtls")
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "java" })
    end,
  },
}
