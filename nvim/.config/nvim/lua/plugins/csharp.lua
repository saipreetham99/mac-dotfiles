-- Replaces OmniSharp (added by the lang.dotnet extra) with the Roslyn
-- language server — the same engine behind VS Code's C# extension.
-- OmniSharp's development has stopped and it doesn't support C# 12+.
--
-- One extra step this file can't do for you: the Roslyn server has no
-- official Mason package, so a community registry has to be added
-- before you can install it. After this file loads, run:
--
--   :Mason  ->  search "roslyn"  ->  install
--
-- (or `:MasonInstall roslyn` once the registry below is picked up).
-- If you hit multiple .sln files in one repo, `:Roslyn target` lets you
-- pick which one to attach to.

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.registries = opts.registries or {}
      table.insert(opts.registries, "github:Crashdummyy/mason-registry")
      return opts
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = false,
      },
    },
  },
  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    ---@module "roslyn.config"
    ---@type RoslynNvimConfig
    opts = {},
  },
}
