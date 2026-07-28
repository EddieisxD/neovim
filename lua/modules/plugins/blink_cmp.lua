--- Blink Completion Spec
local dag_lib = require("library.dag")

return {
  id = "blink_cmp",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "Saghen/blink.cmp",
      id = "blink-cmp",
      event = "InsertEnter",

      -- Explicit keys for manual trigger & docs scrolling without blocking insert-mode <Tab>
      keys = {
        { "<C-Space>", function() require("blink.cmp").show() end, mode = "i", desc = "Blink completion show" },
        { "<C-e>",     function() require("blink.cmp").hide() end, mode = "i", desc = "Blink completion hide" },
        { "<C-b>",     function() require("blink.cmp").scroll_documentation_up(4) end, mode = "i", desc = "Blink scroll docs up" },
        { "<C-f>",     function() require("blink.cmp").scroll_documentation_down(4) end, mode = "i", desc = "Blink scroll docs down" },
      },

      opts = {
        keymap = { preset = "super-tab" }, -- Handles <Tab>/<S-Tab>/<CR> only when completion menu is visible
        appearance = {
          use_nvim_cmp_as_default = true,
          nerd_font_variant = "mono",
        },
        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
        },
      },

      config = function(_, opts)
        local ok, blink = pcall(require, "blink.cmp")
        if ok then
          blink.setup(opts or {})
        end
      end,
    },
  },
  exec = function() end,
}
