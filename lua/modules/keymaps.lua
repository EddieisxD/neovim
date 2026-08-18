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
    if not vim.g.vscode then
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
    end

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

    -- LSP Navigation & Gotos (Explicit bindings for gd, gD, gr, gi, <leader>ca, <leader>rn)
    registry.bind("lsp_definition", vim.lsp.buf.definition, "editor.action.revealDefinition")
    registry.bind("lsp_declaration", vim.lsp.buf.declaration, "editor.action.revealDeclaration")
    registry.bind("lsp_implementation", vim.lsp.buf.implementation, "editor.action.goToImplementation")
    registry.bind("lsp_references", vim.lsp.buf.references, "editor.action.goToReferences")
    registry.bind("lsp_hover", function() vim.lsp.buf.hover({ border = "rounded" }) end, "editor.action.showHover")
    registry.bind("lsp_code_action", vim.lsp.buf.code_action, "editor.action.quickFix", { "n", "x" })
    registry.bind("lsp_rename", vim.lsp.buf.rename, "editor.action.rename")

    -- Open LSP definition in vertical split
    if not vim.g.vscode then
      set("n", "<C-w>gd", function()
        vim.cmd("vsplit")
        vim.lsp.buf.definition()
      end, { desc = "LSP: Open Definition in Vertical Split" })
    end

    -- Floating LSP / Linter Diagnostics Keymaps (with explicit source tags)
    local function open_floating_diagnostic()
      vim.diagnostic.open_float({ border = "rounded", scope = "line", source = "always" })
    end

    registry.bind("diag_float", open_floating_diagnostic, "editor.action.showHover")
    set("n", "gl", open_floating_diagnostic, { desc = "Open floating LSP diagnostic" })
    registry.bind("diag_next", function() vim.diagnostic.goto_next({ float = true }) end, "editor.action.marker.next")
    registry.bind("diag_prev", function() vim.diagnostic.goto_prev({ float = true }) end, "editor.action.marker.prev")

    -- Directional Window Navigation (<C-h/j/k/l>)
    registry.bind("win_left", "<C-w>h", "workbench.action.navigateLeft")
    registry.bind("win_down", "<C-w>j", "workbench.action.navigateDown")
    registry.bind("win_up", "<C-w>k", "workbench.action.navigateUp")
    registry.bind("win_right", "<C-w>l", "workbench.action.navigateRight")
  end,
}
