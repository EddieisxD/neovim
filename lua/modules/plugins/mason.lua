--- Mason Module (Traditional / Lazy Plugin Download Mode)
--- Provides :Mason interface for non-Nix environments while respecting NixOS store paths.

local dag_lib = require("library.dag")

return {
  id = "mason",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options", "lsp" },
  specs = {
    {
      name = "williamboman/mason.nvim",
      id = "mason",
      cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall" },
      opts = {
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      },
      config = function(_, opts)
        local ok, mason = pcall(require, "mason")
        if ok then
          mason.setup(opts or {})
        end
      end,
    },
    {
      name = "williamboman/mason-lspconfig.nvim",
      id = "mason-lspconfig",
      deps = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
      opts = {
        ensure_installed = { "lua_ls" },
        automatic_installation = false,
      },
      config = function(_, opts)
        local ok, mason_lsp = pcall(require, "mason-lspconfig")
        if ok then
          mason_lsp.setup(opts or {})
        end
      end,
    },
  },
  exec = function() end,
}
