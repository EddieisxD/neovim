--- Scope.nvim Module
--- Isolates open buffers to their respective Tab pages so each tab page has its own independent buffer list.

local dag_lib = require("library.dag")

return {
  id = "scope",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "tiagovla/scope.nvim",
      id = "scope",
      event = "VimEnter",
      opts = {},
      config = function(_, opts)
        local ok, scope = pcall(require, "scope")
        if ok then
          scope.setup(opts)
        end
      end,
    },
  },
  exec = function() end,
}
