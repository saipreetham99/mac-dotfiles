return {
  "akinsho/bufferline.nvim",
  opts = {
    options = {
      -- Always show the tabline even with a single buffer
      always_show_bufferline = true,

      -- Smart close: wq when last buffer, bdelete otherwise
      close_command = function(bufnum)
        local listed = vim.fn.getbufinfo({ buflisted = 1 })
        if #listed <= 1 then
          vim.cmd("wq")
        else
          vim.cmd("bdelete! " .. bufnum)
        end
      end,

      -- Also apply same logic to middle-click close
      right_mouse_command = function(bufnum)
        local listed = vim.fn.getbufinfo({ buflisted = 1 })
        if #listed <= 1 then
          vim.cmd("wq")
        else
          vim.cmd("bdelete! " .. bufnum)
        end
      end,
    },
  },
}
