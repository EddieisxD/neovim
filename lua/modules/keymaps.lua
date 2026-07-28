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

    -- Buffer management
    set("n", "<leader>x", function()
      local bufnr = vim.api.nvim_get_current_buf()
      local buftype = vim.bo[bufnr].buftype
      local filetype = vim.bo[bufnr].filetype

      if filetype == "NvimTree" or buftype == "nofile" or buftype == "prompt" or buftype == "quickfix" then
        pcall(vim.cmd, "close")
      else
        local ok = pcall(vim.cmd, "bdelete")
        if not ok then
          pcall(vim.cmd, "bdelete!")
        end
      end
    end, { desc = "Close current buffer", silent = true })

    -- Window navigation
    set("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
    set("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
    set("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
    set("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })
  end,
}
