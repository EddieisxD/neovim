--- Dynamic Formatter Module
--- Sourced dynamically from $PATH (nix-shell, direnv, system) with :Format command & format-on-save toggle.

local dag_lib = require("library.dag")
local logger = require("library.logger")

local M = {}

--- Candidate formatters mapped by filetype
local formatters = {
  lua      = { { bin = "stylua" } },
  nix      = { { bin = "nixfmt" }, { bin = "alejandra" } },
  sh       = { { bin = "shfmt" } },
  bash     = { { bin = "shfmt" } },
  python   = { { bin = "black" }, { bin = "ruff" } },
  rust     = { { bin = "rustfmt" } },
  go       = { { bin = "gofmt" } },
  c        = { { bin = "clang-format" } },
  cpp      = { { bin = "clang-format" } },
  json     = { { bin = "prettier" } },
  markdown = { { bin = "prettier" } },
}

--- Format current buffer using CLI formatter on $PATH or fallback to LSP
function M.format_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  local candidates = formatters[ft] or {}

  -- 1. Try finding a CLI formatter on $PATH
  for _, fmt in ipairs(candidates) do
    if vim.fn.executable(fmt.bin) == 1 then
      logger.debug(string.format("[Formatter] Formatting buffer %d [%s] with '%s'", bufnr, ft, fmt.bin))

      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local input = table.concat(lines, "\n")
      local cmd = (fmt.bin == "stylua") and "stylua -" or fmt.bin
      local output = vim.fn.system(cmd, input)
      if vim.v.shell_error == 0 and #output > 0 then
        local new_lines = vim.split(output, "\n")
        if new_lines[#new_lines] == "" then table.remove(new_lines) end
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
        return
      end
    end
  end

  -- 2. Fallback to LSP formatting if available
  if #vim.lsp.get_clients({ bufnr = bufnr }) > 0 then
    logger.debug(string.format("[Formatter] Falling back to LSP formatting for buffer %d [%s]", bufnr, ft))
    vim.lsp.buf.format({ async = false, bufnr = bufnr })
  end
end

return {
  id = "formatter",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {},

  exec = function()
    -- Register on Bundle bridge so any component can invoke formatting without tight coupling
    if _G.Bundle and _G.Bundle.bridge then
      _G.Bundle.bridge.format = M.format_buffer
    end

    -- Create :Format user command
    vim.api.nvim_create_user_command("Format", function()
      M.format_buffer()
    end, { desc = "Format current buffer with $PATH formatter or LSP" })

    -- Formatter toggle commands owned by Formatter module
    vim.api.nvim_create_user_command("ToggleFormatOnSave", function()
      if _G.Bundle then
        _G.Bundle.settings.format_on_save = not _G.Bundle.settings.format_on_save
        _G.Bundle:notify("Format on Save: " .. tostring(_G.Bundle.settings.format_on_save), vim.log.levels.INFO, "Formatter")
      end
    end, { desc = "Toggle automatic format on save" })

    vim.api.nvim_create_user_command("ToggleFormatter", function()
      if _G.Bundle then
        _G.Bundle.settings.auto_attach_formatter = not _G.Bundle.settings.auto_attach_formatter
        _G.Bundle:notify("Auto-attach Formatter: " .. tostring(_G.Bundle.settings.auto_attach_formatter), vim.log.levels.INFO, "Formatter")
      end
    end, { desc = "Toggle automatic formatter attachment" })

    -- Setup Format on Save if enabled in settings
    local augroup = vim.api.nvim_create_augroup("DAGFormatter", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup,
      callback = function(args)
        local settings = _G.Bundle and _G.Bundle.settings or {}
        if settings.format_on_save ~= false and settings.auto_attach_formatter ~= false then
          M.format_buffer(args.buf)
        end
      end,
    })
  end,
}
