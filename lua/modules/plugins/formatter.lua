--- Dynamic Formatter Module
--- Sourced dynamically from $PATH (nix-shell, direnv, system) with :Format command & format-on-save toggle.

local dag_lib = require("library.dag")
local logger = require("library.logger")

local M = {}

--- Candidate formatters mapped by filetype
local formatters = {
  lua      = { { bin = "stylua", cmd = function(buf) vim.fn.system({ "stylua", "-" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false)) end } },
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

      if fmt.bin == "stylua" then
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local input = table.concat(lines, "\n")
        local output = vim.fn.system("stylua -", input)
        if vim.v.shell_error == 0 and #output > 0 then
          local new_lines = vim.split(output, "\n")
          if new_lines[#new_lines] == "" then table.remove(new_lines) end
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
          return
        end
      elseif fmt.bin == "nixfmt" or fmt.bin == "alejandra" or fmt.bin == "shfmt" or fmt.bin == "black" or fmt.bin == "rustfmt" or fmt.bin == "gofmt" then
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local input = table.concat(lines, "\n")
        local output = vim.fn.system(fmt.bin, input)
        if vim.v.shell_error == 0 and #output > 0 then
          local new_lines = vim.split(output, "\n")
          if new_lines[#new_lines] == "" then table.remove(new_lines) end
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
          return
        end
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
  deps = { "options", "keymaps" },
  specs = {},

  exec = function()
    -- Create :Format user command
    vim.api.nvim_create_user_command("Format", function()
      M.format_buffer()
    end, { desc = "Format current buffer with $PATH formatter or LSP" })

    -- Setup Format on Save if enabled in settings
    local augroup = vim.api.nvim_create_augroup("DAGFormatter", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup,
      callback = function(args)
        local settings = _G.Bundle and _G.Bundle.settings or {}
        if settings.format_on_save ~= false then
          M.format_buffer(args.buf)
        end
      end,
    })
  end,
}
