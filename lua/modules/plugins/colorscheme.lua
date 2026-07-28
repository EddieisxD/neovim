--- Colorscheme Module Spec
local dag_lib = require("library.dag")

return {
  id = "colorscheme",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "catppuccin/nvim",
      id = "catppuccin",
      lazy = false,
      priority = 1000,
      config = function()
        pcall(vim.cmd.colorscheme, "catppuccin-mocha")
      end,
    },
  },
  exec = function()
    -- Direct fallback if no loader is used
    pcall(vim.cmd.colorscheme, "catppuccin-mocha")
  end,
}
