--- Keymaps Module
local dag_lib = require("library.dag")

return {
  id = "keymaps",
  phase = dag_lib.Phases.KEYMAPS,
  deps = { "options" },
  exec = function()
    local set = vim.keymap.set

    set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })
    set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
    set("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })

    -- Window navigation
    set("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
    set("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
    set("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
    set("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })
  end,
}
