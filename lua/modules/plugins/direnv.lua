--- Direnv Integration Module Spec
--- Uses NotAShelf/direnv.nvim (pure Lua direnv manager by NotAShelf / nvf)
--- for zero terminal control sequence leakage, Fidget notifications, and clean process env export.

local dag_lib = require("library.dag")

return {
  id = "direnv",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "NotAShelf/direnv.nvim",
      id = "direnv",
      nix_name = "direnv-nvim",
      lazy = false,
      priority = 100,
      opts = {
        async = true,
        on_direnv_export = function()
          local ok_fidget, fidget = pcall(require, "fidget")
          if ok_fidget and type(fidget.notify) == "function" then
            pcall(fidget.notify, "Nix shell environment updated", vim.log.levels.INFO, { title = "direnv" })
          end
        end,
      },
      config = function(_, opts)
        local ok, direnv = pcall(require, "direnv")
        if ok then
          direnv.setup(opts)
        end
      end,
    },
  },
  exec = function() end,
}
