local M = {}
local term -- one app instance at a time, so port 8080 doesn't collide

local function has_spring(path)
  if vim.fn.filereadable(path) == 0 then
    return false
  end
  return table.concat(vim.fn.readfile(path), "\n"):find("spring-boot", 1, true) ~= nil
end

local function command(root)
  local function exists(name)
    return vim.fn.filereadable(root .. "/" .. name) == 1
  end
  if has_spring(root .. "/pom.xml") then
    return exists("mvnw") and "./mvnw spring-boot:run" or "mvn spring-boot:run"
  end
  if has_spring(root .. "/build.gradle") or has_spring(root .. "/build.gradle.kts") then
    return exists("gradlew") and "./gradlew bootRun" or "gradle bootRun"
  end
end

-- Returns true if it handled the run, false to fall back to run_code.
function M.run()
  local file = vim.api.nvim_buf_get_name(0)
  local root = vim.fs.root(file, { "pom.xml", "build.gradle", "build.gradle.kts" })
  local cmd = root and command(root)
  if not cmd then
    return false
  end

  vim.cmd("silent! wall")
  if term then
    term:shutdown() -- clicking again restarts the app
  end
  term = require("toggleterm.terminal").Terminal:new({
    cmd = cmd,
    dir = root,
    direction = "float",
    close_on_exit = false,
  })
  term:toggle()
  return true
end

return M
