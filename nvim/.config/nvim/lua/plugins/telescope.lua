-- Patterns to exclude from the directory pickers below (fd --exclude glob
-- syntax). Add more here as you run into noisy directories, e.g. "node_modules",
-- "target", "dist", "build", ".venv" — one string per line.
local dir_excludes = {
  ".git",
  "node_modules",
}

-- The directory to treat as "here": prefers oil's current dir (since
-- oil.open() doesn't change Neovim's actual cwd), falls back to the open
-- file's directory, then finally to Neovim's cwd.
local function current_dir()
  local ok, oil = pcall(require, "oil")
  if ok and vim.bo.filetype == "oil" then
    return oil.get_current_dir()
  end
  local file_dir = vim.fn.expand("%:p:h")
  if file_dir ~= "" and vim.fn.isdirectory(file_dir) == 1 then
    return file_dir
  end
  return vim.loop.cwd()
end

-- Finds the git root of `current_dir()`, falling back to it as-is if
-- there's no .git (e.g. outside a repo).
local function project_root()
  local dir = current_dir()
  local git_dir = vim.fs.find(".git", { path = dir, upward = true })[1]
  if git_dir then
    return vim.fn.fnamemodify(git_dir, ":h")
  end
  return dir
end

-- Builds the fd command for the directory pickers, applying dir_excludes.
local function find_dirs_command()
  local cmd = { "fd", "--type", "d" }
  for _, pattern in ipairs(dir_excludes) do
    table.insert(cmd, "--exclude")
    table.insert(cmd, pattern)
  end
  return cmd
end

-- Unique, existing parent directories of Neovim's oldfiles list (persists
-- across sessions via shada), most-recent first.
local function recent_dirs()
  local seen, dirs = {}, {}
  for _, file in ipairs(vim.v.oldfiles) do
    local dir = vim.fn.fnamemodify(file, ":h")
    if dir ~= "" and vim.fn.isdirectory(dir) == 1 and not seen[dir] then
      seen[dir] = true
      table.insert(dirs, dir)
    end
  end
  return dirs
end

-- Shared by both directory pickers below: <CR> opens the pick in oil
-- instead of telescope's normal "open this file" behavior.
local function open_in_oil(prompt_bufnr)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local entry = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  if not entry then
    return
  end
  -- find_files entries are relative to whatever `cwd` the picker was given
  -- (entry[1]); entry.path is the same value already joined into an
  -- absolute path. Our recent_dirs() picker has no `.path` field at all
  -- since its entries are plain absolute strings, so entry[1] is correct
  -- there.
  require("oil").open(entry.path or entry[1])
end

return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  keys = {
    {
      "<leader>fd",
      function()
        require("telescope.builtin").find_files({
          prompt_title = "Find Directory (project root)",
          cwd = project_root(),
          find_command = find_dirs_command(),
          attach_mappings = function(_, map)
            map("i", "<CR>", open_in_oil)
            map("n", "<CR>", open_in_oil)
            return true
          end,
        })
      end,
      desc = "Find Directory (project root)",
    },
    {
      "<leader>fD",
      function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values

        pickers
          .new({}, {
            prompt_title = "Recent Directories",
            finder = finders.new_table({ results = recent_dirs() }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(_, map)
              map("i", "<CR>", open_in_oil)
              map("n", "<CR>", open_in_oil)
              return true
            end,
          })
          :find()
      end,
      desc = "Find Recent Directory",
    },
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
