-- Clickable "Load Maven Changes" button, like IntelliJ's floating reload icon.
-- After saving pom.xml (or a Gradle build file) a button appears in the
-- winbar; clicking it tells jdtls to re-import the project, which downloads
-- new dependencies into ~/.m2 and puts them on the classpath.
local build_files = { "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts" }
local pending = {}

vim.api.nvim_set_hl(0, "MavenReloadButton", { fg = "#1a1b26", bg = "#7aa2f7", bold = true })

local function set_winbar(bufnr, value)
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    vim.wo[win].winbar = value
  end
end

local function show_button(bufnr)
  pending[bufnr] = true
  local label = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t") == "pom.xml" and "Maven" or "Gradle"
  set_winbar(
    bufnr,
    "%#MavenReloadButton#%" .. bufnr .. "@v:lua.MavenReloadClick@ 󰑓 Load " .. label .. " Changes %X%*"
      .. "%#Comment#  click or <leader>cM%*"
  )
end

local function hide_button(bufnr)
  pending[bufnr] = nil
  set_winbar(bufnr, "")
end

local function find_client(path)
  local clients = vim.lsp.get_clients({ name = "jdtls" })
  for _, client in ipairs(clients) do
    local root = client.root_dir or (client.config and client.config.root_dir)
    if root and path:sub(1, #root) == root then
      return client
    end
  end
  return clients[1]
end

local function reload(bufnr)
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  local client = find_client(path)
  if not client then
    vim.notify("jdtls is not running — open a .java file in this project first", vim.log.levels.WARN)
    return
  end
  if vim.bo[bufnr].modified then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("silent write")
    end)
  end
  -- jdtls defines this as a notification, so there's no response to wait
  -- for; the import's own progress "end" event tells us when it's done.
  if not client:notify("java/projectConfigurationUpdate", { uri = vim.uri_from_fname(path) }) then
    vim.notify("Build reload failed: could not reach jdtls", vim.log.levels.ERROR)
    return
  end
  hide_button(bufnr)
  vim.notify("Importing build changes (downloading dependencies)…")

  local group = vim.api.nvim_create_augroup("maven_reload_progress", { clear = true })
  vim.api.nvim_create_autocmd("LspProgress", {
    group = group,
    pattern = "end",
    callback = function(args)
      if args.data.client_id == client.id then
        vim.api.nvim_del_augroup_by_id(group)
        vim.notify("Build changes loaded")
      end
    end,
  })
  -- Stop listening if jdtls never reports progress (e.g. nothing changed).
  vim.defer_fn(function()
    pcall(vim.api.nvim_del_augroup_by_id, group)
  end, 120000)
end

_G.MavenReloadClick = function(minwid)
  reload(minwid)
end

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = build_files,
  callback = function(args)
    show_button(args.buf)
  end,
})

-- Keep the button when the buffer is shown in a new window.
vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = build_files,
  callback = function(args)
    if pending[args.buf] then
      show_button(args.buf)
    end
  end,
})

vim.api.nvim_create_autocmd("BufDelete", {
  pattern = build_files,
  callback = function(args)
    pending[args.buf] = nil
  end,
})

vim.keymap.set("n", "<leader>cM", function()
  reload(vim.api.nvim_get_current_buf())
end, { desc = "Load Maven/Gradle changes" })
