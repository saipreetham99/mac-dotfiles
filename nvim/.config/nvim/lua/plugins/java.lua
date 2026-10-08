-- Extra jdtls settings layered on top of LazyVim's lang.java extra.
-- lazy.nvim deep-merges these into the extra's opts, so its lombok,
-- inlay hints, dap and test setup are all kept as-is.
return {
  {
    "mfussenegger/nvim-jdtls",
    opts = {
      settings = {
        java = {
          -- re-import pom.xml / build.gradle changes without prompting
          configuration = { updateBuildConfiguration = "automatic" },
          -- fetch library sources so hover / completion docs show real Javadoc
          eclipse = { downloadSources = true },
          maven = { downloadSources = true },
          -- decompile classes that have no sources when jumping to a definition
          contentProvider = { preferred = "fernflower" },
          references = { includeDecompiledSources = true },
          signatureHelp = { enabled = true, description = { enabled = true } },
          -- never collapse imports into `import java.util.*`
          sources = {
            organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
          },
          completion = {
            -- offered as completions, static import added automatically
            favoriteStaticMembers = {
              "org.junit.jupiter.api.Assertions.*",
              "org.junit.Assert.*",
              "org.mockito.Mockito.*",
              "org.mockito.ArgumentMatchers.*",
              "java.util.Objects.requireNonNull",
              "java.util.Objects.requireNonNullElse",
              "java.util.stream.Collectors.*",
            },
            -- hidden from completion and auto-import (e.g. java.awt.List)
            filteredTypes = {
              "com.sun.*",
              "io.micrometer.shaded.*",
              "java.awt.*",
              "jdk.*",
              "sun.*",
            },
            importOrder = { "java", "javax", "jakarta", "org", "com", "" },
          },
          -- used by the "Generate ..." code actions (<leader>ca)
          codeGeneration = {
            useBlocks = true,
            toString = {
              template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
            },
          },
        },
      },
    },
  },
  {
    -- parameter hints while typing call arguments (all languages, not just Java)
    "saghen/blink.cmp",
    opts = { signature = { enabled = true } },
  },
}
