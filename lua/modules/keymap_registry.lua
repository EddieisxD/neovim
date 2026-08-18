--- Centralized Keymap Registry & Universal Adapter Engine
--- Single source of truth for all keybindings across Neovim TUI, Neovide, and VSCode/VSCodium environments.
--- Automatically maps semantic actions to Neovim Lua commands or VSCode actions depending on runtime environment.

local dag_lib = require("library.dag")

local M = {}

--- Helper to safely execute a VSCode action with multi-adapter fallback
local function vscode_action(action_id)
  local ok, vscode = pcall(require, "vscode")
  if ok and vscode and type(vscode.action) == "function" then
    vscode.action(action_id)
    return
  end

  local ok_vn, vn = pcall(require, "vscode-neovim")
  if ok_vn and vn then
    if type(vn.action) == "function" then
      vn.action(action_id)
      return
    elseif type(vn.call) == "function" then
      vn.call(action_id)
      return
    end
  end

  if vim.fn.exists("*VSCodeNotify") == 1 then
    pcall(vim.fn.VSCodeNotify, action_id)
  else
    pcall(vim.cmd, "call VSCodeNotify('" .. action_id .. "')")
  end
end

M.vscode_action = vscode_action

--- Centralized Keymap Registry Table
M.registry = {
  -- Buffer & Editor Actions
  close_buffer  = { key = "<leader>x",  desc = "Close active buffer / editor" },
  next_buffer   = { key = "]b",         desc = "Switch to next open buffer" },
  prev_buffer   = { key = "[b",         desc = "Switch to previous open buffer" },
  save_file     = { key = "<leader>w",   desc = "Save file" },
  quit          = { key = "<leader>q",   desc = "Quit window / editor" },

  -- File Explorer & Sidebar Navigation
  toggle_sidebar = { key = "<C-b>",      desc = "Toggle primary sidebar / explorer" },
  focus_tree     = { key = "<leader>e",  desc = "Toggle focus between buffer and explorer" },
  find_files     = { key = "<leader>ff", desc = "Find files" },
  live_grep      = { key = "<leader>fw", desc = "Live grep search" },
  find_buffers   = { key = "<leader>fb", desc = "Find open buffers" },

  -- Formatting & Tooling
  format_buffer = { key = "<leader>fm",  desc = "Format current buffer" },

  -- LSP Gotos, Hover, Code Actions & Rename
  lsp_definition     = { key = "gd",         desc = "Go to Definition" },
  lsp_declaration    = { key = "gD",         desc = "Go to Declaration" },
  lsp_implementation = { key = "gi",         desc = "Go to Implementation" },
  lsp_references     = { key = "gr",         desc = "Go to References" },
  lsp_hover          = { key = "K",          desc = "Hover Documentation" },
  lsp_code_action    = { key = "<leader>ca", desc = "Code Actions / Quickfix" },
  lsp_rename         = { key = "<leader>rn", desc = "Rename Symbol" },

  -- Diagnostics
  diag_float = { key = "<leader>cd", desc = "Line Diagnostics Float" },
  diag_next  = { key = "]d",         desc = "Next Diagnostic" },
  diag_prev  = { key = "[d",         desc = "Previous Diagnostic" },

  -- Window Splits & Tabs
  split_vert    = { key = "<leader>sv",  desc = "Split window vertically" },
  split_horiz   = { key = "<leader>sh",  desc = "Split window horizontally" },
  split_equal   = { key = "<leader>se",  desc = "Make window splits equal size" },
  split_close   = { key = "<leader>sx",  desc = "Close current split window" },
  split_to_tab  = { key = "<leader>st",  desc = "Move current split into a new tab page" },
  tab_next      = { key = "gt",          desc = "Switch to next tab page" },
  tab_prev      = { key = "gT",          desc = "Switch to previous tab page" },

  -- Window Directional Navigation
  win_left  = { key = "<C-h>", desc = "Focus left window split" },
  win_down  = { key = "<C-j>", desc = "Focus lower window split" },
  win_up    = { key = "<C-k>", desc = "Focus upper window split" },
  win_right = { key = "<C-l>", desc = "Focus right window split" },

  -- DAP Debugger
  toggle_bp     = { key = "<leader>db",  desc = "Toggle Breakpoint" },
  continue_dap  = { key = "<leader>dc",  desc = "Continue Debugger" },
  toggle_dap_ui = { key = "<leader>du",  desc = "Toggle Debugger UI" },
}

--- Bind a semantic keymap action dynamically based on runtime environment (TUI / Neovide vs VSCode)
---@param action_name string Key name in M.registry
---@param tui_target string|function Command string or Lua function for TUI / Neovide
---@param vscode_action_id? string|function Optional VSCode action ID or handler for VSCode environment
---@param modes? string|table Mode string or table (default: "n")
function M.bind(action_name, tui_target, vscode_action_id, modes)
  local item = M.registry[action_name]
  if not item then return end
  modes = modes or "n"

  if vim.g.vscode then
    if type(vscode_action_id) == "function" then
      vim.keymap.set(modes, item.key, vscode_action_id, { desc = item.desc })
    elseif type(vscode_action_id) == "string" then
      vim.keymap.set(modes, item.key, function()
        vscode_action(vscode_action_id)
      end, { desc = item.desc })
    end
  else
    if type(tui_target) == "function" then
      vim.keymap.set(modes, item.key, tui_target, { desc = item.desc })
    elseif type(tui_target) == "string" then
      vim.keymap.set(modes, item.key, "<cmd>" .. tui_target .. "<CR>", { desc = item.desc })
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
      M.bind("close_buffer",      nil, "workbench.action.closeActiveEditor")
      M.bind("next_buffer",       nil, "workbench.action.nextEditor")
      M.bind("prev_buffer",       nil, "workbench.action.previousEditor")
      M.bind("toggle_sidebar",    nil, "workbench.action.toggleSidebarVisibility", { "n", "x" })
      M.bind("focus_tree",        nil, "workbench.files.action.focusFilesExplorer")
      M.bind("find_files",        nil, "workbench.action.quickOpen")
      M.bind("live_grep",         nil, "workbench.action.findInFiles")
      M.bind("find_buffers",      nil, "workbench.action.showAllEditors")
      M.bind("save_file",         nil, "workbench.action.files.save")
      M.bind("quit",              nil, "workbench.action.closeActiveEditor")
      M.bind("format_buffer",     nil, "editor.action.formatDocument")

      -- LSP & Navigation
      M.bind("lsp_definition",     nil, "editor.action.revealDefinition")
      M.bind("lsp_declaration",    nil, "editor.action.revealDeclaration")
      M.bind("lsp_implementation", nil, "editor.action.goToImplementation")
      M.bind("lsp_references",     nil, "editor.action.goToReferences")
      M.bind("lsp_hover",          nil, "editor.action.showHover")
      M.bind("lsp_code_action",    nil, "editor.action.quickFix", { "n", "x" })
      M.bind("lsp_rename",         nil, "editor.action.rename")

      -- Diagnostics
      M.bind("diag_float",         nil, "editor.action.showHover")
      M.bind("diag_next",          nil, "editor.action.marker.next")
      M.bind("diag_prev",          nil, "editor.action.marker.prev")

      -- Splits & Navigation
      M.bind("split_vert",        nil, "workbench.action.splitEditor")
      M.bind("split_horiz",       nil, "workbench.action.splitEditorOrthogonal")
      M.bind("split_equal",       nil, "workbench.action.evenEditorWidths")
      M.bind("split_close",       nil, "workbench.action.closeActiveEditor")
      M.bind("split_to_tab",      nil, "workbench.action.moveEditorToNewWindow")
      M.bind("tab_next",          nil, "workbench.action.nextEditor")
      M.bind("tab_prev",          nil, "workbench.action.previousEditor")
      M.bind("win_left",          nil, "workbench.action.navigateLeft")
      M.bind("win_down",          nil, "workbench.action.navigateDown")
      M.bind("win_up",            nil, "workbench.action.navigateUp")
      M.bind("win_right",         nil, "workbench.action.navigateRight")

      -- Debugging
      M.bind("toggle_bp",         nil, "workbench.action.debug.toggleBreakpoint")
      M.bind("continue_dap",      nil, "workbench.action.debug.start")
      M.bind("toggle_dap_ui",     nil, "workbench.view.debug")
    end
  end,
  api = M,
}
