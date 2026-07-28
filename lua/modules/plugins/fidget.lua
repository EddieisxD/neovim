--- Fidget UI Module
local dag_lib = require("library.dag")

return {
  id = "fidget",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options", "lsp" },
  specs = {
    {
      name = "j-hui/fidget.nvim",
      id = "fidget",
      event = "LspAttach",
      opts = {
        notification = {
          window = {
            winblend = 0,
            normal_hl = "Comment",
          },
        },
        progress = {
          suppress_on_insert = true,
        },
      },
      config = function(_, opts)
        local ok, fidget = pcall(require, "fidget")
        if ok then
          fidget.setup(opts or {})
        end
      end,
    },
  },
  exec = function() end,
}
