--- WhichKey Keybind Popup Module Spec
local dag_lib = require("library.dag")

return {
  id = "which_key",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options", "keymaps" },
  specs = {
    {
      name = "folke/which-key.nvim",
      nix_name = "which-key-nvim",
      id = "which-key",
      enabled = not vim.g.vscode,
      event = "VeryLazy",
      keys = {
        { "<leader>wK", "<cmd>WhichKey<CR>", desc = "WhichKey all keymaps" },
        {
          "<leader>wk",
          function()
            vim.cmd("WhichKey " .. vim.fn.input("WhichKey: "))
          end,
          desc = "WhichKey query lookup",
        },
      },
      opts = {
        preset = "classic",
        win = { border = "rounded" },
      },
      config = function(_, opts)
        if vim.g.vscode then return end
        local ok, wk = pcall(require, "which-key")
        if ok then
          wk.setup(opts or {})
        end
      end,
    },
  },
  exec = function() end,
}
