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
      cmd = { "ConformInfo", "Format", "Formatter" },
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

    -- Unified :Formatter <subcommand> [formatter_name] command suite
    local formatter_subcommands = { "enable", "disable", "toggle", "format", "info" }
    local available_formatters = { "stylua", "nixfmt", "alejandra", "shfmt", "black", "ruff", "rustfmt", "gofmt", "prettier", "clang-format" }

    local function formatter_complete(arg_lead, cmd_line, cursor_pos)
      local parts = vim.split(cmd_line, "%s+", { trimempty = true })
      if #parts == 1 or (#parts == 2 and not cmd_line:match("%s$")) then
        local matches = {}
        for _, sub in ipairs(formatter_subcommands) do
          if sub:find(arg_lead, 1, true) == 1 then table.insert(matches, sub) end
        end
        return matches
      elseif #parts >= 2 then
        local matches = {}
        for _, fmt in ipairs(available_formatters) do
          if fmt:find(arg_lead, 1, true) == 1 then table.insert(matches, fmt) end
        end
        return matches
      end
      return {}
    end

    vim.api.nvim_create_user_command("Formatter", function(opts)
      local args = vim.split(opts.args, "%s+", { trimempty = true })
      local sub = args[1]

      if not sub or sub == "format" then
        local ok, conform = pcall(require, "conform")
        if ok then conform.format({ async = true, lsp_fallback = true }) end
      elseif sub == "enable" then
        if _G.Bundle then _G.Bundle.settings.auto_attach_formatter = true end
        vim.notify("Formatter enabled", vim.log.levels.INFO, { title = "Formatter" })
      elseif sub == "disable" then
        if _G.Bundle then _G.Bundle.settings.auto_attach_formatter = false end
        vim.notify("Formatter disabled", vim.log.levels.INFO, { title = "Formatter" })
      elseif sub == "toggle" then
        if _G.Bundle then
          _G.Bundle.settings.auto_attach_formatter = not _G.Bundle.settings.auto_attach_formatter
          vim.notify("Auto-attach Formatter: " .. tostring(_G.Bundle.settings.auto_attach_formatter), vim.log.levels.INFO, { title = "Formatter" })
        end
      elseif sub == "info" then
        pcall(vim.cmd, "ConformInfo")
      end
    end, {
      nargs = "*",
      complete = formatter_complete,
      desc = "Unified Formatter Suite (:Formatter enable|disable|toggle|format|info)",
    })

    vim.cmd("cabbrev formatter Formatter")
  end,
}
