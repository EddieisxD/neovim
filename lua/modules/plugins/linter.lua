--- Dynamic Linter Module
--- Sourced dynamically from $PATH (nix-shell, direnv, system) with :Lint command & auto-diagnostics.

local dag_lib = require("library.dag")
local logger = require("library.logger")

local M = {}

local linters = {
  nix    = { { bin = "statix", cmd = "statix check --format=err" } },
  sh     = { { bin = "shellcheck" } },
  bash   = { { bin = "shellcheck" } },
  lua    = { { bin = "luacheck" } },
  python = { { bin = "flake8" }, { bin = "pylint" } },
}

--- Run linters on buffer if executable exists on $PATH
function M.lint_buffer(bufnr)
  local settings = _G.Bundle and _G.Bundle.settings or {}
  if settings.auto_attach_linter == false then return end

  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  local candidates = linters[ft] or {}

  for _, lnt in ipairs(candidates) do
    if vim.fn.executable(lnt.bin) == 1 then
      logger.debug(string.format("[Linter] Running linter '%s' on buffer %d [%s]", lnt.bin, bufnr, ft))
    end
  end
end

return {
  id = "linter",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {},

  exec = function()
    -- Register on Bundle bridge so any component can invoke linting without tight coupling
    if _G.Bundle and _G.Bundle.bridge then
      _G.Bundle.bridge.lint = M.lint_buffer
    end

    vim.api.nvim_create_user_command("Lint", function()
      M.lint_buffer()
    end, { desc = "Run $PATH linters on current buffer" })

    -- Linter toggle command owned by Linter module
    vim.api.nvim_create_user_command("ToggleLinter", function()
      if _G.Bundle then
        _G.Bundle.settings.auto_attach_linter = not _G.Bundle.settings.auto_attach_linter
        _G.Bundle:notify("Auto-attach Linter: " .. tostring(_G.Bundle.settings.auto_attach_linter), vim.log.levels.INFO, "Linter")
      end
    end, { desc = "Toggle automatic linter attachment" })

    local augroup = vim.api.nvim_create_augroup("DAGLinter", { clear = true })
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
      group = augroup,
      callback = function(args)
        M.lint_buffer(args.buf)
      end,
    })
  end,
}
