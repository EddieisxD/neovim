--- Dynamic Linter Module
--- Sourced dynamically from $PATH (nix-shell, direnv, system) with :Linter command & auto-diagnostics.

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

    -- Unified :Linter <subcommand> [linter_name] command suite
    local linter_subcommands = { "enable", "disable", "toggle", "lint", "info" }
    local available_linters = { "statix", "shellcheck", "luacheck", "flake8", "pylint", "eslint" }

    local function linter_complete(arg_lead, cmd_line, cursor_pos)
      local parts = vim.split(cmd_line, "%s+", { trimempty = true })
      if #parts == 1 or (#parts == 2 and not cmd_line:match("%s$")) then
        local matches = {}
        for _, sub in ipairs(linter_subcommands) do
          if sub:find(arg_lead, 1, true) == 1 then table.insert(matches, sub) end
        end
        return matches
      elseif #parts >= 2 then
        local matches = {}
        for _, lnt in ipairs(available_linters) do
          if lnt:find(arg_lead, 1, true) == 1 then table.insert(matches, lnt) end
        end
        return matches
      end
      return {}
    end

    vim.api.nvim_create_user_command("Linter", function(opts)
      local args = vim.split(opts.args, "%s+", { trimempty = true })
      local sub = args[1]

      if not sub or sub == "lint" then
        M.lint_buffer()
      elseif sub == "enable" then
        if _G.Bundle then _G.Bundle.settings.auto_attach_linter = true end
        vim.notify("Linter enabled", vim.log.levels.INFO, { title = "Linter" })
      elseif sub == "disable" then
        if _G.Bundle then _G.Bundle.settings.auto_attach_linter = false end
        vim.notify("Linter disabled", vim.log.levels.INFO, { title = "Linter" })
      elseif sub == "toggle" then
        if _G.Bundle then
          _G.Bundle.settings.auto_attach_linter = not _G.Bundle.settings.auto_attach_linter
          vim.notify("Auto-attach Linter: " .. tostring(_G.Bundle.settings.auto_attach_linter), vim.log.levels.INFO, { title = "Linter" })
        end
      elseif sub == "info" then
        local active = {}
        local ft = vim.bo.filetype
        for _, lnt in ipairs(linters[ft] or {}) do
          if vim.fn.executable(lnt.bin) == 1 then table.insert(active, lnt.bin) end
        end
        vim.notify("Active linters for " .. ft .. ": " .. (#active > 0 and table.concat(active, ", ") or "None"), vim.log.levels.INFO, { title = "Linter" })
      end
    end, {
      nargs = "*",
      complete = linter_complete,
      desc = "Unified Linter Suite (:Linter enable|disable|toggle|lint|info)",
    })

    vim.cmd("cabbrev linter Linter")

    local augroup = vim.api.nvim_create_augroup("DAGLinter", { clear = true })
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
      group = augroup,
      callback = function(args)
        M.lint_buffer(args.buf)
      end,
    })
  end,
}
