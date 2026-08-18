--- Dynamic Linter Module with mfussenegger/nvim-lint
--- Asynchronous linting sourced dynamically from $PATH binaries with unified :Linter command suite.

local dag_lib = require("library.dag")
local logger = require("library.logger")

return {
  id = "linter",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "mfussenegger/nvim-lint",
      id = "lint",
      nix_name = "nvim-lint",
      enabled = not vim.g.vscode,
      event = { "BufReadPost", "BufWritePost" },
      cmd = { "Lint", "Linter" },
      opts = {
        linters_by_ft = {
          nix = { "statix" },
          sh = { "shellcheck" },
          bash = { "shellcheck" },
          lua = { "luacheck" },
          python = { "flake8" },
          javascript = { "eslint" },
          typescript = { "eslint" },
        },
      },
      config = function(_, opts)
        if vim.g.vscode then return end
        local ok, lint = pcall(require, "lint")
        if ok then
          lint.linters_by_ft = opts.linters_by_ft or {}

          local augroup = vim.api.nvim_create_augroup("DAGLinterAuto", { clear = true })
          vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
            group = augroup,
            callback = function()
              local settings = _G.Bundle and _G.Bundle.settings or {}
              if settings.auto_attach_linter ~= false then
                pcall(lint.try_lint)
              end
            end,
          })
        end
      end,
    },
  },

  exec = function()
    if vim.g.vscode then return end
    -- Register on Bundle bridge so any component can invoke linting without tight coupling
    if _G.Bundle and _G.Bundle.bridge then
      _G.Bundle.bridge.lint = function()
        local ok, lint = pcall(require, "lint")
        if ok then pcall(lint.try_lint) end
      end
    end

    -- Create :Lint user command
    vim.api.nvim_create_user_command("Lint", function()
      local ok, lint = pcall(require, "lint")
      if ok then pcall(lint.try_lint) end
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
        local ok, lint = pcall(require, "lint")
        if ok then pcall(lint.try_lint) end
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
        local ok, lint = pcall(require, "lint")
        local active = {}
        local ft = vim.bo.filetype
        if ok and lint.linters_by_ft[ft] then
          for _, name in ipairs(lint.linters_by_ft[ft]) do
            local lnt = lint.linters[name]
            local cmd = type(lnt) == "table" and lnt.cmd or name
            if vim.fn.executable(cmd) == 1 then table.insert(active, name) end
          end
        end
        vim.notify("Active linters for " .. ft .. ": " .. (#active > 0 and table.concat(active, ", ") or "None"), vim.log.levels.INFO, { title = "Linter" })
      end
    end, {
      nargs = "*",
      complete = linter_complete,
      desc = "Unified Linter Suite (:Linter enable|disable|toggle|lint|info)",
    })

    -- Safe command-position abbreviation
    vim.cmd([[cabbrev <expr> linter (getcmdtype() == ':' && getcmdline() ==# 'linter') ? 'Linter' : 'linter']])
  end,
}
