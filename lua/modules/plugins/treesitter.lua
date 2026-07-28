--- Treesitter Module Spec
local dag_lib = require("library.dag")

return {
  id = "treesitter",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "nvim-treesitter/nvim-treesitter",
      id = "nvim-treesitter",
      event = { "BufReadPost", "BufNewFile" },
      cmd = { "TSUpdate", "TSInstall" },
      opts = {
        highlight = { enable = true },
        indent = { enable = true },
        ensure_installed = { "lua", "vim", "vimdoc", "query", "bash", "nix" },
      },
      config = function()
        local ok, ts = pcall(require, "nvim-treesitter.configs")
        if ok then
          ts.setup({
            highlight = { enable = true },
            indent = { enable = true },
          })
        end
      end,
    },
  },
  exec = function() end,
}
