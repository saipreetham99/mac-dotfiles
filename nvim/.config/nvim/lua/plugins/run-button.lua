-- Clickable statusline button. Uses LazyVim's existing lualine.nvim.
return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Mouse support is needed to click statusline components in terminal Neovim.
      vim.opt.mouse:append("a")
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      table.insert(opts.sections.lualine_x, 1, {
        function()
          return "▶ Run"
        end,
        cond = function()
          return require("config.run_code").is_supported()
        end,
        on_click = function(_, button)
          if button == "l" then
            require("config.run_code").run()
          end
        end,
        color = { fg = "#9ece6a", gui = "bold" }, -- Tokyo Night green
      })
    end,
  },
}
