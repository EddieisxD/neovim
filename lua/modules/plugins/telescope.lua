--- Telescope Module Spec
local dag_lib = require("library.dag")

return {
  id = "telescope",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options", "keymaps" },
  specs = {
    {
      name = "nvim-telescope/telescope.nvim",
      id = "telescope",
      deps = { "nvim-lua/plenary.nvim" },
      cmd = "Telescope",
      keys = {
        { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
        { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Live Grep" },
      },
      config = function()
        local ok, telescope = pcall(require, "telescope")
        if ok then
          telescope.setup({})
        end
      end,
    },
  },
  exec = function() end,
}
