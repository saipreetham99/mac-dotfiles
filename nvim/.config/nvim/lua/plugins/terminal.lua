return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      direction = "float",
      float_opts = {
        border = "rounded",
        width = function()
          return math.floor(vim.o.columns * 0.9)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.85)
        end,
        winblend = 0,
      },
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      close_on_exit = false,
      shade_terminals = false,
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      local Terminal = require("toggleterm.terminal").Terminal

      -- Shared by the plain shell terminals only — nchat gets its own
      -- on_open below instead, since it needs esc/ctrl-q/etc for itself.
      local function shell_on_open(term)
        local buf = term.bufnr
        vim.keymap.set("t", "<esc>", [[<c-\><c-n>]], { buffer = buf, silent = true })
        vim.keymap.set("t", "<c-h>", [[<c-\><c-n><c-w>h]], { buffer = buf, silent = true })
        vim.keymap.set("t", "<c-j>", [[<c-\><c-n><c-w>j]], { buffer = buf, silent = true })
        vim.keymap.set("t", "<c-k>", [[<c-\><c-n><c-w>k]], { buffer = buf, silent = true })
        vim.keymap.set("t", "<c-l>", [[<c-\><c-n><c-w>l]], { buffer = buf, silent = true })
        vim.keymap.set("t", "<c-q>", [[<c-\><c-n>:close<cr>]], { buffer = buf, silent = true })
      end

      local float_term = Terminal:new({
        direction = "float",
        hidden = true,
        float_opts = opts.float_opts,
        on_open = shell_on_open,
      })

      local hsplit_term = Terminal:new({
        direction = "horizontal",
        hidden = true,
        size = 15,
        on_open = shell_on_open,
      })

      local vsplit_term = Terminal:new({
        direction = "vertical",
        hidden = true,
        size = function()
          return math.floor(vim.o.columns * 0.4)
        end,
        on_open = shell_on_open,
      })

      local nchat_term = Terminal:new({
        cmd = "COLORTERM=truecolor nchat",
        direction = "float",
        hidden = true,
        float_opts = opts.float_opts,
        on_open = function(term)
          vim.keymap.set("t", "<C-b>", function()
            vim.cmd("stopinsert")
            term:toggle()
          end, { buffer = term.bufnr, silent = true, desc = "Hide nchat window" })
        end,
      })

      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { silent = true, noremap = true, desc = desc })
      end

      map("n", "<leader>tt", function()
        float_term:toggle()
      end, "Terminal (Float)")

      map("n", "<leader>th", function()
        hsplit_term:toggle()
      end, "Terminal (Horizontal)")

      map("n", "<leader>tv", function()
        vsplit_term:toggle()
      end, "Terminal (Vertical)")

      map("n", "<leader>tw", function()
        nchat_term:toggle()
      end, "WhatsApp (nchat)")

      -- Applies to every terminal, nchat included: window chrome, and the
      -- one Normal-mode "q" close — safe everywhere since it only fires
      -- once you're already out of terminal-mode.
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "*",
        callback = function(args)
          local buf = args.buf
          local win = vim.api.nvim_get_current_win()

          vim.wo[win].number = false
          vim.wo[win].relativenumber = false
          vim.wo[win].signcolumn = "no"
          vim.bo[buf].buflisted = false

          vim.keymap.set("n", "q", ":close<cr>", { buffer = buf, silent = true })
        end,
      })
    end,
  },
}
