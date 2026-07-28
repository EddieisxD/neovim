--- Telescope Module Spec
--- Custom layout: Bottom prompt bar with 30% Fuzzy Results / 70% Preview split.

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

      -- Telescope Keybindings declared directly in spec
      keys = {
        { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
        { "<leader>fw", "<cmd>Telescope live_grep<cr>",  desc = "Live Grep" },
        { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Live Grep" },
        { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Find Buffers" },
        { "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "Help Tags" },
        { "<leader>fa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<cr>", desc = "Find All Files" },
      },

      config = function()
        local ok, telescope = pcall(require, "telescope")
        if not ok then return end

        local vimgrep_args = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
        }

        telescope.setup({
          defaults = {
            vimgrep_arguments = vimgrep_args,
            layout_strategy = "horizontal",
            layout_config = {
              prompt_position = "bottom",
              horizontal = {
                preview_width = 0.70,
                results_width = 0.30,
              },
              width = 0.90,
              height = 0.90,
            },
          },
        })
      end,
    },
  },
  exec = function() end,
}
