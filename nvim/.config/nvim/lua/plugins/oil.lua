if vim.env.NCHAT_PICK_OUTPUT then
  vim.keymap.set("n", "<C-y>", function()
    local oil = require("oil")
    local entry = oil.get_cursor_entry()
    if entry then
      local path = oil.get_current_dir() .. entry.name
      local f = io.open(vim.env.NCHAT_PICK_OUTPUT, "w")
      if f then
        f:write(path)
        f:close()
      end
    end
    vim.cmd("qa!")
  end, { desc = "Pick file for nchat" })

  vim.keymap.set("n", "<Esc>", function()
    vim.cmd("qa!")
  end, { desc = "Cancel file pick for nchat" })
end

return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Oil",
    opts = {
      default_file_explorer = true,
      skip_confirm_for_simple_edits = true,
      view_options = {
        show_hidden = true,
      },
      preview_win = {
        update_on_cursor_moved = true,
        disable_preview = function(filename)
          local ext = filename:match("%.([^.]+)$")
          local image_exts = {
            png = true,
            jpg = true,
            jpeg = true,
            gif = true,
            webp = true,
            bmp = true,
            svg = true,
          }
          return ext ~= nil and image_exts[ext:lower()] == true
        end,
      },
    },
    config = function(_, opts)
      local oil = require("oil")
      oil.setup(opts)

      local orig = oil.load_oil_buffer
      oil.load_oil_buffer = function(bufnr)
        bufnr = bufnr or vim.api.nvim_get_current_buf()
        if vim.b[bufnr].oil_ready then
          return
        end
        return orig(bufnr)
      end
    end,
    keys = {
      {
        "<leader>o",
        function()
          require("oil").open(nil, { preview = { vertical = true, split = "botright" } })
        end,
        desc = "Oil (with preview)",
      },
      {
        "<leader>O",
        function()
          require("oil").open_float()
        end,
        desc = "Oil float",
      },
    },
  },
}
