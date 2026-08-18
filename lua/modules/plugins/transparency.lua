--- Unified All-or-Nothing Transparency Engine
--- Provides a single factored-out entrypoint (M.apply_transparency) for applying UI transparency
--- across boot initialization, colorscheme changes, and user command toggles.

local dag_lib = require("library.dag")
local logger = require("library.logger")

local M = {}

--- Complete list of UI highlight groups cleared when transparency is enabled
--- (Note: TabLineSel is intentionally excluded so active buffer pills remain colored by the active theme)
local all_groups = {
  "Normal", "NormalNC", "NormalFloat", "FloatBorder",
  "NonText", "EndOfBuffer",
  "SignColumn", "LineNr", "CursorLineNr", "FoldColumn",
  "VertSplit", "WinSeparator",
  "StatusLine", "StatusLineNC",
  "TabLine", "TabLineFill", "MsgArea",
  -- Top Bufferbar Container Layer Highlights
  "lualine_c_normal", "lualine_c_inactive", "lualine_c_replace", "lualine_c_insert", "lualine_c_visual", "lualine_c_command",
  "lualine_b_normal", "lualine_b_inactive", "lualine_a_buffers_inactive", "lualine_b_buffers_inactive", "lualine_c_buffers_inactive",
  -- Sign Column Git & LSP Diagnostics Highlights
  "GitSignsAdd", "GitSignsChange", "GitSignsDelete", "GitSignsTopdelete", "GitSignsChangedelete", "GitSignsUntracked",
  "DiagnosticSignError", "DiagnosticSignWarn", "DiagnosticSignInfo", "DiagnosticSignHint",
  -- Fidget Notifications
  "FidgetTitle", "FidgetTask", "FidgetNormal",
  -- NvimTree File Explorer
  "NvimTreeNormal", "NvimTreeNormalNC", "NvimTreeEndOfBuffer", "NvimTreeWinSeparator",
  -- Telescope Fuzzy Finder
  "TelescopeNormal", "TelescopeBorder",
  "TelescopePromptNormal", "TelescopePromptBorder", "TelescopePromptTitle",
  "TelescopeResultsNormal", "TelescopeResultsBorder", "TelescopeResultsTitle",
  "TelescopePreviewNormal", "TelescopePreviewBorder", "TelescopePreviewTitle",
  -- Popup Menu & Floats
  "Pmenu", "PmenuSbar", "PmenuThumb",
}

--- Single factored-out function that applies or clears transparency based on Bundle.state.transparent
function M.apply_transparency()
  if vim.g.vscode then return end
  local is_trans = _G.Bundle and _G.Bundle.state and _G.Bundle.state.transparent == true

  if is_trans then
    for _, g in ipairs(all_groups) do
      vim.api.nvim_set_hl(0, g, { bg = "none" })
    end
    vim.api.nvim_set_hl(0, "MsgArea", { bg = "none" })
    logger.info("[Transparency Engine] Applied UI transparency (bg = none)")
  else
    -- Re-apply colorscheme highlights cleanly to restore solid backgrounds without stripping foreground styles
    local scheme = (_G.Bundle and _G.Bundle.state and _G.Bundle.state.colorscheme) or vim.g.colors_name or "catppuccin-mocha"
    local ok_cs, cs_mod = pcall(require, "modules.plugins.colorscheme")
    if ok_cs and cs_mod.api and type(cs_mod.api.set_colorscheme) == "function" then
      cs_mod.api.set_colorscheme(scheme)
    end
    vim.api.nvim_set_hl(0, "MsgArea", { link = "Normal" })
    logger.info("[Transparency Engine] Restored solid colorscheme backgrounds")
  end
end

--- Enable transparency state, persist to disk, and synchronize UI
function M.enable()
  if _G.Bundle then
    _G.Bundle.state.transparent = true
    _G.Bundle:save_state()
  end

  local scheme = (_G.Bundle and _G.Bundle.state and _G.Bundle.state.colorscheme) or vim.g.colors_name or "catppuccin-mocha"
  local ok_cs, cs_mod = pcall(require, "modules.plugins.colorscheme")
  if ok_cs and cs_mod.api and type(cs_mod.api.set_colorscheme) == "function" then
    cs_mod.api.set_colorscheme(scheme)
  end

  M.apply_transparency()
end

--- Disable transparency state, persist to disk, and restore solid theme
function M.disable()
  if _G.Bundle then
    _G.Bundle.state.transparent = false
    _G.Bundle:save_state()
  end

  M.apply_transparency()

  -- Refresh Lualine theme non-destructively
  local scheme = (_G.Bundle and _G.Bundle.state and _G.Bundle.state.colorscheme) or vim.g.colors_name or "catppuccin-mocha"
  local ok_l, lualine_inst = pcall(require, "lualine")
  if ok_l and type(lualine_inst.set_theme) == "function" then
    pcall(lualine_inst.set_theme, scheme)
  end
end

--- Toggle transparency state on or off & persist to disk
function M.toggle()
  local is_trans = _G.Bundle and _G.Bundle.state and _G.Bundle.state.transparent == true
  if is_trans then
    M.disable()
    if vim.notify then vim.notify("Transparency OFF (Solid Backgrounds Restored)", vim.log.levels.INFO) end
  else
    M.enable()
    if vim.notify then vim.notify("Transparency ON (All UI Backgrounds Cleared)", vim.log.levels.INFO) end
  end
end

return {
  id = "transparency",
  phase = dag_lib.Phases.POST,
  deps = { "colorscheme" },
  exec = function()
    if vim.g.vscode then return end

    -- User Commands
    vim.api.nvim_create_user_command("ToggleTransparency", function()
      M.toggle()
    end, { desc = "Toggle full UI transparency on/off" })

    vim.api.nvim_create_user_command("ApplyTransparency", function()
      M.enable()
    end, { desc = "Apply transparency over current colorscheme" })

    -- Auto-synchronize transparency whenever colorscheme changes
    local augroup = vim.api.nvim_create_augroup("DAGTransparency", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = augroup,
      callback = function()
        M.apply_transparency()
      end,
    })

    -- Single unified boot initialization call
    M.apply_transparency()
  end,
  api = M,
}
