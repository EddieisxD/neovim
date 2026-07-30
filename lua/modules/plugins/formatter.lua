--- Conform.nvim Formatter Engine
--- Asynchronous code formatting sourced dynamically from $PATH binaries with fallback to LSP.

local dag_lib = require("library.dag")
local logger = require("library.logger")

return {
  id = "formatter",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "stevearc/conform.nvim",
      id = "conform",
      nix_name = "conform-nvim",
      event = { "BufWritePre" },
      cmd = { "ConformInfo", "Format" },
      keys = {
        {
          "<leader>fm",
          function()
            local ok, conform = pcall(require, "conform")
            if ok then
              conform.format({ async = true, lsp_fallback = true })
              if _G.Bundle and _G.Bundle.notify then
                _G.Bundle:notify("Formatted buffer", vim.log.levels.INFO, { title = "conform" })
              end
            end
          end,
          desc = "Format current buffer",
        },
      },
      opts = {
        formatters_by_ft = {
          lua = { "stylua" },
          nix = { "nixfmt", "alejandra", stop_after_first = true },
          sh = { "shfmt" },
          bash = { "shfmt" },
          python = { "black", "ruff", stop_after_first = true },
          rust = { "rustfmt" },
          go = { "gofmt" },
          c = { "clang-format" },
          cpp = { "clang-format" },
          json = { "prettier" },
          markdown = { "prettier" },
        },
        format_on_save = function(bufnr)
          local settings = _G.Bundle and _G.Bundle.settings or {}
          if settings.format_on_save and settings.auto_attach_formatter ~= false then
            return { timeout_ms = 1000, lsp_fallback = true }
          end
          return nil
        end,
      },
      config = function(_, opts)
        local ok, conform = pcall(require, "conform")
        if ok then
          conform.setup(opts or {})
        end
      end,
    },
  },
  exec = function()
    -- Register on Bundle bridge so any component can trigger formatting
    if _G.Bundle and _G.Bundle.bridge then
      _G.Bundle.bridge.format = function(bufnr)
        local ok, conform = pcall(require, "conform")
        if ok then
          conform.format({ bufnr = bufnr, async = true, lsp_fallback = true })
        end
      end
    end

    -- Create :Format user command
    vim.api.nvim_create_user_command("Format", function()
      local ok, conform = pcall(require, "conform")
      if ok then
        conform.format({ async = true, lsp_fallback = true })
      end
    end, { desc = "Format current buffer with conform.nvim" })

    -- Formatter toggle commands
    vim.api.nvim_create_user_command("ToggleFormatOnSave", function()
      if _G.Bundle then
        _G.Bundle.settings.format_on_save = not _G.Bundle.settings.format_on_save
        _G.Bundle:notify("Format on Save: " .. tostring(_G.Bundle.settings.format_on_save), vim.log.levels.INFO, { title = "Formatter" })
      end
    end, { desc = "Toggle automatic format on save" })

    vim.api.nvim_create_user_command("ToggleFormatter", function()
      if _G.Bundle then
        _G.Bundle.settings.auto_attach_formatter = not _G.Bundle.settings.auto_attach_formatter
        _G.Bundle:notify("Auto-attach Formatter: " .. tostring(_G.Bundle.settings.auto_attach_formatter), vim.log.levels.INFO, { title = "Formatter" })
      end
    end, { desc = "Toggle automatic formatter attachment" })
  end,
}
