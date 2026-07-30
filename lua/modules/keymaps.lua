--- Keymaps Module
--- Defines general navigation, buffer management, and floating diagnostic keymaps.

local dag_lib = require("library.dag")

return {
  id = "keymaps",
  phase = dag_lib.Phases.KEYMAPS,
  deps = { "options", "keymap_registry" },
  exec = function()
    local set = vim.keymap.set
    local registry = require("modules.keymap_registry").api

    set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

    -- Synced Keymaps (Auto-adapts between Neovim TUI and VSCode/VSCodium)
    registry.bind("save_file", "w", "workbench.action.files.save")
    registry.bind("quit", "q", "workbench.action.closeActiveEditor")

    registry.bind("close_buffer", function()
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
    end, "workbench.action.closeActiveEditor")

    -- Floating LSP Diagnostics Keymaps
    local function open_floating_diagnostic()
      vim.diagnostic.open_float({ border = "rounded", scope = "line" })
    end

    set("n", "<leader>cd", open_floating_diagnostic, { desc = "Open floating LSP diagnostic" })
    set("n", "<leader>e", open_floating_diagnostic, { desc = "Open floating LSP diagnostic" })
    set("n", "gl", open_floating_diagnostic, { desc = "Open floating LSP diagnostic" })
    set("n", "]d", function() vim.diagnostic.goto_next({ float = true }) end, { desc = "Next LSP diagnostic" })
    set("n", "[d", function() vim.diagnostic.goto_prev({ float = true }) end, { desc = "Previous LSP diagnostic" })

    -- Window navigation
    set("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
    set("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
    set("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
    set("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })
  end,
}
