--- NvimTree File Explorer Module (Sourced from NvChad)
local dag_lib = require("library.dag")

return {
  id = "file_explorer",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "nvim-tree/nvim-tree.lua",
      id = "nvim-tree",
      deps = { "nvim-tree/nvim-web-devicons" },
      cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },

      -- Plugin-dependent keybindings specified directly in plugin spec
      keys = {
        { "<C-n>",      "<cmd>NvimTreeToggle<CR>", desc = "NvimTree toggle window" },
        { "<leader>e",  "<cmd>NvimTreeFocus<CR>",  desc = "NvimTree focus window" },
      },

      opts = {
        filters = { dotfiles = false },
        disable_netrw = true,
        hijack_netrw = true,
        hijack_cursor = true,
        view = {
          width = 30,
          side = "left",
        },
      },

      config = function(_, opts)
        local ok, tree = pcall(require, "nvim-tree")
        if ok then
          tree.setup(opts or {})
        end
      end,
    },
  },
  exec = function() end,
}
