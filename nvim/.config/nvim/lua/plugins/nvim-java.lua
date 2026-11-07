-- lua/plugins/nvim-java.lua  (nvim-jdtls + spring-boot.nvim)

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

local function collect_bundles()
  local ok, mason_registry = pcall(require, "mason-registry")
  if not ok then
    return {}
  end

  local bundles = {}

  if mason_registry.is_installed("java-debug-adapter") then
    local debug_jar = vim.fn.glob(
      mason_registry.get_package("java-debug-adapter"):get_install_path()
        .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"
    )
    if debug_jar ~= "" then
      table.insert(bundles, debug_jar)
    end
  end

  if mason_registry.is_installed("java-test") then
    for _, jar in ipairs(vim.fn.glob(
      mason_registry.get_package("java-test"):get_install_path()
        .. "/extension/server/*.jar",
      false,
      true
    )) do
      if
        not jar:find("com.microsoft.java.test.runner")
        and not jar:find("jacocoagent")
        and not jar:find("org.objectweb.asm")
      then
        table.insert(bundles, jar)
      end
    end
  end

  local spring_ok, spring_boot = pcall(require, "spring_boot")
  if spring_ok then
    vim.list_extend(bundles, spring_boot.java_extensions())
  end

  return bundles
end

return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    config = function()
      local bundles = collect_bundles()

      vim.lsp.config("jdtls", {
        settings = {
          java = {
            signatureHelp = { enabled = true },
            contentProvider = { preferred = "fernflower" },
            completion = {
              favoriteStaticMembers = {
                "org.hamcrest.MatcherAssert.assertThat",
                "org.hamcrest.Matchers.*",
                "org.hamcrest.CoreMatchers.*",
                "org.junit.jupiter.api.Assertions.*",
                "java.util.Objects.requireNonNull",
                "java.util.Objects.requireNonNullElse",
                "org.mockito.Mockito.*",
              },
              filteredTypes = {
                "com.sun.*",
                "io.micrometer.shaded.*",
                "java.awt.*",
                "jdk.*",
                "sun.*",
              },
            },
            sources = {
              organizeImports = {
                starThreshold = 9999,
                staticStarThreshold = 9999,
              },
            },
            codeGeneration = {
              toString = {
                template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
              },
              useBlocks = true,
            },
          },
        },
        init_options = {
          bundles = bundles,
        },
        on_attach = function(client, bufnr)
          local jdtls = require("jdtls")
          pcall(function()
            jdtls.setup_dap({ hotcodereplace = "auto" })
          end)

          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
          end
          map("n", "<leader>co", jdtls.organize_imports, "Organize imports")
          map("n", "<leader>cv", jdtls.extract_variable, "Extract variable")
          map("v", "<leader>cv", function()
            jdtls.extract_variable(true)
          end, "Extract variable")
          map("v", "<leader>cm", function()
            jdtls.extract_method(true)
          end, "Extract method")
        end,
      })
      vim.lsp.enable("jdtls")
    end,
  },

  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    dependencies = {
      "mfussenegger/nvim-jdtls",
    },
    opts = {},
  },

  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "jdtls",
        "java-debug-adapter",
        "java-test",
        "vscode-spring-boot-tools",
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "java" })
    end,
  },
}
