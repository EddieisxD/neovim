--- Keymaps Module
--- Defines general navigation, buffer management, floating diagnostic keymaps, and tooling toggles.

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

    -- Tooling Toggle Commands & Controls
    vim.api.nvim_create_user_command("ToggleFormatOnSave", function()
      if _G.Bundle then
        _G.Bundle.settings.format_on_save = not _G.Bundle.settings.format_on_save
        vim.notify("Format on Save: " .. tostring(_G.Bundle.settings.format_on_save), vim.log.levels.INFO)
      end
    end, { desc = "Toggle automatic format on save" })

    vim.api.nvim_create_user_command("ToggleFormatter", function()
      if _G.Bundle then
        _G.Bundle.settings.auto_attach_formatter = not _G.Bundle.settings.auto_attach_formatter
        vim.notify("Auto-attach Formatter: " .. tostring(_G.Bundle.settings.auto_attach_formatter), vim.log.levels.INFO)
      end
    end, { desc = "Toggle automatic formatter attachment" })

    vim.api.nvim_create_user_command("ToggleLinter", function()
      if _G.Bundle then
        _G.Bundle.settings.auto_attach_linter = not _G.Bundle.settings.auto_attach_linter
        vim.notify("Auto-attach Linter: " .. tostring(_G.Bundle.settings.auto_attach_linter), vim.log.levels.INFO)
      end
    end, { desc = "Toggle automatic linter attachment" })

    vim.api.nvim_create_user_command("ToggleDAP", function()
      if _G.Bundle then
        _G.Bundle.settings.auto_attach_dap = not _G.Bundle.settings.auto_attach_dap
        vim.notify("Auto-attach DAP Debugger: " .. tostring(_G.Bundle.settings.auto_attach_dap), vim.log.levels.INFO)
      end
    end, { desc = "Toggle automatic DAP debugger attachment" })
  end,
}
