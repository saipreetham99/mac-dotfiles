-- Clickable ▶ gutter sign next to the entry point, like GUI IDEs.
return {
  {
    dir = vim.fn.stdpath("config"),
    name = "run-button",
    event = "VeryLazy",
    config = function()
      local ns = vim.api.nvim_create_namespace("run_button")
      local supported = { java = true, python = true, cpp = true }

      vim.api.nvim_set_hl(0, "RunSign", { fg = "#9ece6a", bold = true })
      vim.api.nvim_set_hl(0, "RunButton", { fg = "#1a1b26", bg = "#9ece6a", bold = true })
      vim.api.nvim_set_hl(0, "RunButtonIcon", { fg = "#9ece6a", bold = true })

      local function find_entry_line(bufnr)
        local ft = vim.bo[bufnr].filetype
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        if ft == "java" then
          for i, line in ipairs(lines) do
            if line:match("void%s+main%s*%(") then
              return i
            end
          end
        elseif ft == "python" then
          for i, line in ipairs(lines) do
            if line:match("^if%s+__name__%s*==") then
              return i
            end
          end
          return 1
        elseif ft == "cpp" then
          for i, line in ipairs(lines) do
            if line:match("^%s*int%s+main%s*%(") then
              return i
            end
          end
        end
      end

      local function update_sign(bufnr)
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
        local line = find_entry_line(bufnr)
        if line then
          vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
            sign_text = "▶",
            sign_hl_group = "RunSign",
            virt_lines_above = true,
            virt_lines = {
              {
                { "  ▶ Run ", "RunButton" },
                { "  <leader>rr", "Comment" },
              },
            },
          })
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "java", "python", "cpp" },
        callback = function(args)
          update_sign(args.buf)
        end,
      })

      vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
        callback = function(args)
          if supported[vim.bo[args.buf].filetype] then
            update_sign(args.buf)
          end
        end,
      })

      -- Cover buffers already open before VeryLazy fired.
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) and supported[vim.bo[bufnr].filetype] then
          update_sign(bufnr)
        end
      end

      -- TestNG/JUnit ▶ Run | Debug buttons share the click handler below.
      local test_runner = require("config.test_runner")
      test_runner.setup()

      -- Click the ▶ sign or the virtual "Run" line to run.
      vim.opt.mouse:append("a")
      vim.keymap.set("n", "<LeftMouse>", function()
        local pos = vim.fn.getmousepos()
        if test_runner.click(pos) then
          return
        end
        local bufnr = vim.fn.winbufnr(pos.winid)
        if bufnr ~= -1 and supported[vim.bo[bufnr].filetype] then
          local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
          if #marks > 0 then
            local mark_line = marks[1][2] + 1
            local wininfo = vim.fn.getwininfo(pos.winid)
            local textoff = wininfo and wininfo[1] and wininfo[1].textoff or 0
            local on_gutter = pos.wincol <= textoff and pos.wincol > 0
            local on_virt_line = pos.line == mark_line and pos.screenrow < vim.fn.screenpos(pos.winid, mark_line, 1).row
            if (on_gutter and pos.line == mark_line) or on_virt_line then
              require("config.run_code").run()
              return
            end
          end
        end
        local key = vim.api.nvim_replace_termcodes("<LeftMouse>", true, true, true)
        vim.api.nvim_feedkeys(key, "n", false)
      end)
    end,
  },
}
