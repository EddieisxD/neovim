--- Keymaps Module
--- Defines general navigation, window splits, tabpages, buffer management, LSP gotos (gd, gD, gr, gi), hover (K), and floating diagnostic keymaps.

local dag_lib = require("library.dag")

return {
  id = "keymaps",
  phase = dag_lib.Phases.KEYMAPS,
  deps = { "options", "keymap_registry" },
  exec = function()
    local set = vim.keymap.set
    local registry = require("modules.keymap_registry").api

    -- Smart <Esc> - Closes open floating windows (LSP Hover, Diagnostics) and clears search highlights
    set("n", "<Esc>", function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(win)
        if config and config.relative and config.relative ~= "" then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
      vim.cmd("nohlsearch")
    end, { desc = "Close floating windows and clear search highlights" })

    -- Synced Keymaps (Auto-adapts between Neovim TUI and VSCode/VSCodium)
    registry.bind("save_file", "w", "workbench.action.files.save")
    registry.bind("quit", "q", "workbench.action.closeActiveEditor")

    -- Buffer Management & Bracket Switching Suite ([b / ]b)
    registry.bind("next_buffer", "bnext", "workbench.action.nextEditor")
    registry.bind("prev_buffer", "bprevious", "workbench.action.previousEditor")

    -- Window Split & Tabpage Management Suite
    registry.bind("split_vert", "vsplit", "workbench.action.splitEditor")
    registry.bind("split_horiz", "split", "workbench.action.splitEditorOrthogonal")
    registry.bind("split_equal", "<C-w>=", "workbench.action.evenEditorWidths")
    registry.bind("split_close", "close", "workbench.action.closeActiveEditor")

    -- Split to Tab Movement (<leader>st / <C-w>T)
    registry.bind("split_to_tab", "wincmd T", "workbench.action.moveEditorToNewWindow")
    registry.bind("tab_next", "tabnext", "workbench.action.nextEditor")
    registry.bind("tab_prev", "tabprevious", "workbench.action.previousEditor")

    -- Move buffer from tab back into a split in the previous tab, then close current tab
    set("n", "<leader>sm", function()
      local cur_buf = vim.api.nvim_get_current_buf()
      local num_tabs = vim.fn.tabpagenr("$")
      if num_tabs > 1 then
        vim.cmd("tabclose")
        vim.cmd("vsplit")
        vim.api.nvim_set_current_buf(cur_buf)
      else
        vim.cmd("vsplit")
      end
    end, { desc = "Move tab buffer back into a vertical split" })

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

    -- LSP Navigation & Gotos (Explicit bindings for gd, gD, gr, gi, <leader>ca)
    set("n", "gd", vim.lsp.buf.definition, { desc = "LSP: Go to Definition / Open Wikilink Note" })
    set("n", "gD", vim.lsp.buf.declaration, { desc = "LSP: Go to Declaration" })
    set("n", "gi", vim.lsp.buf.implementation, { desc = "LSP: Go to Implementation" })
    set("n", "gr", vim.lsp.buf.references, { desc = "LSP: Go to References / Vault Backlinks" })
    set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP: Code Actions / Quickfixes" })

    -- Open LSP definition / wikilink in vertical split
    set("n", "<C-w>gd", function()
      vim.cmd("vsplit")
      vim.lsp.buf.definition()
    end, { desc = "LSP: Open Definition / Wikilink in Vertical Split" })

    -- LSP Hover Window (K) - Displays signatures & markdown docs for built-in and custom functions
    set("n", "K", function()
      vim.lsp.buf.hover({ border = "rounded" })
    end, { desc = "LSP Hover Documentation & Function Signatures" })

    -- Floating LSP / Linter Diagnostics Keymaps (with explicit source tags)
    local function open_floating_diagnostic()
      vim.diagnostic.open_float({ border = "rounded", scope = "line", source = "always" })
    end

    set("n", "<leader>cd", open_floating_diagnostic, { desc = "Open floating LSP diagnostic" })
    set("n", "gl", open_floating_diagnostic, { desc = "Open floating LSP diagnostic" })
    set("n", "]d", function() vim.diagnostic.goto_next({ float = true }) end, { desc = "Next LSP diagnostic" })
    set("n", "[d", function() vim.diagnostic.goto_prev({ float = true }) end, { desc = "Previous LSP diagnostic" })

    -- Directional Window Navigation (<C-h/j/k/l>)
    set("n", "<C-h>", "<C-w>h", { desc = "Focus left window split" })
    set("n", "<C-j>", "<C-w>j", { desc = "Focus lower window split" })
    set("n", "<C-k>", "<C-w>k", { desc = "Focus upper window split" })
    set("n", "<C-l>", "<C-w>l", { desc = "Focus right window split" })
  end,
}
