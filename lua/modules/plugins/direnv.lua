--- Direnv Integration Module Spec
--- Automatically exports environment variables from direnv / nix-direnv into Neovim.
--- Sourced on DirChanged, BufReadPost, and BufNewFile events.

local dag_lib = require("library.dag")

return {
  id = "direnv",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "direnv/direnv.vim",
      id = "direnv",
      nix_name = "direnv-vim",
      event = { "BufReadPost", "BufNewFile", "DirChanged" },
      config = function()
        vim.g.direnv_auto_reload = 1
        vim.g.direnv_silent_load = 1
      end,
    },
  },
  exec = function() end,
}
