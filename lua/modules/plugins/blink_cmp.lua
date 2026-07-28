--- Blink Completion Spec (Sourced from NvChad keybinds & blink.cmp)
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

      -- Plugin-dependent keybindings declared directly in spec
      keys = {
        { "<C-Space>", function() require("blink.cmp").show() end, mode = "i", desc = "Blink completion show" },
        { "<C-e>",     function() require("blink.cmp").hide() end, mode = "i", desc = "Blink completion hide" },
        { "<C-p>",     function() require("blink.cmp").select_prev() end, mode = "i", desc = "Blink completion prev item" },
        { "<C-n>",     function() require("blink.cmp").select_next() end, mode = "i", desc = "Blink completion next item" },
        { "<C-b>",     function() require("blink.cmp").scroll_documentation_up(4) end, mode = "i", desc = "Blink scroll docs up" },
        { "<C-f>",     function() require("blink.cmp").scroll_documentation_down(4) end, mode = "i", desc = "Blink scroll docs down" },
        { "<Tab>",     function() require("blink.cmp").select_next() end, mode = "i", desc = "Blink select next" },
        { "<S-Tab>",   function() require("blink.cmp").select_prev() end, mode = "i", desc = "Blink select prev" },
        { "<CR>",      function() require("blink.cmp").accept() end, mode = "i", desc = "Blink accept completion" },
      },

      opts = {
        keymap = { preset = "default" },
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
