--- Centralized Keymap Registry & Universal Adapter Engine
--- Single source of truth for all keybindings across Neovim TUI, Neovide, and VSCode/VSCodium environments.
--- Automatically maps semantic actions to Neovim Lua commands or VSCode actions depending on runtime environment.

local dag_lib = require("library.dag")

local M = {}

--- Centralized Keymap Registry Table
M.registry = {
  close_buffer  = { key = "<leader>x",  desc = "Close active buffer / tab" },
  toggle_tree   = { key = "<C-n>",       desc = "Toggle file explorer" },
  focus_tree    = { key = "<leader>e",   desc = "Focus file explorer" },
  find_files    = { key = "<leader>ff",  desc = "Find files" },
  live_grep     = { key = "<leader>fw",  desc = "Live grep search" },
  find_buffers  = { key = "<leader>fb",  desc = "Find open buffers" },
  save_file     = { key = "<leader>w",   desc = "Save file" },
  quit          = { key = "<leader>q",   desc = "Quit" },
  format_buffer = { key = "<leader>fm",  desc = "Format current buffer" },
  toggle_bp     = { key = "<leader>db",  desc = "Toggle DAP Breakpoint" },
  continue_dap  = { key = "<leader>dc",  desc = "Continue DAP Debugger" },
  toggle_dap_ui = { key = "<leader>du",  desc = "Toggle DAP UI Panels" },
}

--- Bind a semantic keymap action dynamically based on runtime environment (TUI / Neovide vs VSCode)
---@param action_name string Key name in M.registry
---@param tui_target string|function Command string or Lua function for TUI / Neovide
---@param vscode_action_id? string Optional VSCode action ID for VSCodium environment
function M.bind(action_name, tui_target, vscode_action_id)
  local item = M.registry[action_name]
  if not item then return end

  if vim.g.vscode then
    if vscode_action_id then
      local ok, vscode = pcall(require, "vscode")
      if ok then
        vim.keymap.set("n", item.key, function()
          vscode.action(vscode_action_id)
        end, { desc = item.desc })
      end
    end
  else
    if type(tui_target) == "function" then
      vim.keymap.set("n", item.key, tui_target, { desc = item.desc })
    elseif type(tui_target) == "string" then
      vim.keymap.set("n", item.key, "<cmd>" .. tui_target .. "<CR>", { desc = item.desc })
    end
  end
end

return {
  id = "keymap_registry",
  phase = dag_lib.Phases.KEYMAPS - 5,
  deps = { "options" },
  exec = function()
    -- Register default VSCode bindings on startup if in VSCode mode
    if vim.g.vscode then
      M.bind("close_buffer",  nil, "workbench.action.closeActiveEditor")
      M.bind("toggle_tree",   nil, "workbench.action.toggleSidebarVisibility")
      M.bind("focus_tree",    nil, "workbench.files.action.focusFilesExplorer")
      M.bind("find_files",    nil, "workbench.action.quickOpen")
      M.bind("live_grep",     nil, "workbench.action.findInFiles")
      M.bind("save_file",     nil, "workbench.action.files.save")
      M.bind("quit",          nil, "workbench.action.closeActiveEditor")
      M.bind("format_buffer", nil, "editor.action.formatDocument")
    end
  end,
  api = M,
}
