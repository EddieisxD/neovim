--- DAP Debugger Engine Module
--- Integrates nvim-dap, nvim-dap-ui, and nvim-dap-virtual-text with unified :Dap suite and keymaps.

local dag_lib = require("library.dag")

return {
  id = "dap",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options", "keymap_registry" },
  specs = {
    {
      name = "mfussenegger/nvim-dap",
      id = "dap",
      nix_name = "nvim-dap",
      enabled = not vim.g.vscode,
      cmd = { "DapToggleBreakpoint", "DapContinue", "Dap" },
      keys = {
        { "<leader>db", function() local ok, dap = pcall(require, "dap") if ok then dap.toggle_breakpoint() end end, desc = "Toggle DAP Breakpoint" },
        { "<leader>dc", function() local ok, dap = pcall(require, "dap") if ok then dap.continue() end end, desc = "Continue DAP Debugger" },
        { "<leader>du", function() local ok, dapui = pcall(require, "dapui") if ok then dapui.toggle() end end, desc = "Toggle DAP UI" },
      },
      deps = {
        "rcarriga/nvim-dap-ui",
        "theHamsta/nvim-dap-virtual-text",
        "nvim-neotest/nvim-nio",
      },
      config = function()
        if vim.g.vscode then return end
        local ok_dap, dap = pcall(require, "dap")
        local ok_dapui, dapui = pcall(require, "dapui")
        local ok_vt, vt = pcall(require, "nvim-dap-virtual-text")

        if ok_dapui then dapui.setup({}) end
        if ok_vt then vt.setup({}) end

        -- Curated DAP Breakpoint signs matching render-markdown.nvim aesthetic
        vim.fn.sign_define("DapBreakpoint", { text = "󰏤 ", texthl = "DiagnosticError", linehl = "", numhl = "" })
        vim.fn.sign_define("DapBreakpointRejected", { text = "󰏦 ", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
        vim.fn.sign_define("DapLogPoint", { text = "󰦪 ", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
        vim.fn.sign_define("DapStopped", { text = "󰁔 ", texthl = "DiagnosticOk", linehl = "DapStoppedLine", numhl = "" })

        if ok_dap and ok_dapui then
          dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
          dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
          dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
        end
      end,
    },
  },

  exec = function()
    local registry = require("modules.keymap_registry").api
    registry.bind("toggle_bp", function()
      local ok, dap = pcall(require, "dap")
      if ok then dap.toggle_breakpoint() end
    end, "workbench.action.debug.toggleBreakpoint")

    registry.bind("continue_dap", function()
      local ok, dap = pcall(require, "dap")
      if ok then dap.continue() end
    end, "workbench.action.debug.start")

    registry.bind("toggle_dap_ui", function()
      local ok, dapui = pcall(require, "dapui")
      if ok then dapui.toggle() end
    end, "workbench.view.debug")

    if vim.g.vscode then return end

    -- Unified :Dap <subcommand> [adapter_name] command suite
    local dap_subcommands = { "enable", "disable", "toggle", "start", "toggle_breakpoint", "ui_toggle", "info" }
    local available_adapters = { "codelldb", "python", "go" }

    local function dap_complete(arg_lead, cmd_line, cursor_pos)
      local parts = vim.split(cmd_line, "%s+", { trimempty = true })
      if #parts == 1 or (#parts == 2 and not cmd_line:match("%s$")) then
        local matches = {}
        for _, sub in ipairs(dap_subcommands) do
          if sub:find(arg_lead, 1, true) == 1 then table.insert(matches, sub) end
        end
        return matches
      elseif #parts >= 2 then
        local matches = {}
        for _, adapter in ipairs(available_adapters) do
          if adapter:find(arg_lead, 1, true) == 1 then table.insert(matches, adapter) end
        end
        return matches
      end
      return {}
    end

    vim.api.nvim_create_user_command("Dap", function(opts)
      local args = vim.split(opts.args, "%s+", { trimempty = true })
      local sub = args[1]

      if not sub or sub == "start" then
        local ok, dap = pcall(require, "dap")
        if ok then dap.continue() end
      elseif sub == "toggle_breakpoint" then
        local ok, dap = pcall(require, "dap")
        if ok then dap.toggle_breakpoint() end
      elseif sub == "ui_toggle" then
        local ok, dapui = pcall(require, "dapui")
        if ok then dapui.toggle() end
      elseif sub == "enable" then
        if _G.Bundle then _G.Bundle.settings.auto_attach_dap = true end
        vim.notify("DAP Debugger enabled", vim.log.levels.INFO, { title = "DAP" })
      elseif sub == "disable" then
        if _G.Bundle then _G.Bundle.settings.auto_attach_dap = false end
        vim.notify("DAP Debugger disabled", vim.log.levels.INFO, { title = "DAP" })
      elseif sub == "toggle" then
        if _G.Bundle then
          _G.Bundle.settings.auto_attach_dap = not _G.Bundle.settings.auto_attach_dap
          vim.notify("Auto-attach DAP: " .. tostring(_G.Bundle.settings.auto_attach_dap), vim.log.levels.INFO, { title = "DAP" })
        end
      elseif sub == "info" then
        local ok, dap = pcall(require, "dap")
        local session = ok and dap.session()
        vim.notify("DAP Session: " .. (session and session.config.name or "No active debug session"), vim.log.levels.INFO, { title = "DAP" })
      end
    end, {
      nargs = "*",
      complete = dap_complete,
      desc = "Unified DAP Suite (:Dap enable|disable|toggle|start|toggle_breakpoint|ui_toggle|info)",
    })

    -- Safe command-position abbreviation
    vim.cmd([[cabbrev <expr> dap (getcmdtype() == ':' && getcmdline() ==# 'dap') ? 'Dap' : 'dap']])
  end,
}
