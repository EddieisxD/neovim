--- Fidget UI Module
--- Registers fidget.notify subscriber into Bundle.notify_handler for decoupled visual notification rendering.

local dag_lib = require("library.dag")

return {
  id = "fidget",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options", "lsp" },
  specs = {
    {
      name = "j-hui/fidget.nvim",
      id = "fidget",
      lazy = false,
      priority = 90,
      event = { "VimEnter", "LspAttach" },
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
          if _G.Bundle then
            _G.Bundle.notify_handler = fidget.notify
          end
        end
      end,
    },
  },
  exec = function() end,
}
