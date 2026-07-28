--- All-or-Nothing Transparency Engine
--- Toggles full UI transparency (including NvimTree, Telescope, Floats & Statuslines)
--- and automatically persists transparency state cross-session in bundle_state.json.

local dag_lib = require("library.dag")
local logger = require("library.logger")

local M = {}

--- Complete list of UI highlight groups for total transparency
local all_groups = {
  "Normal", "NormalNC", "NormalFloat", "FloatBorder",
  "NonText", "EndOfBuffer",
  "SignColumn", "LineNr", "FoldColumn",
  "VertSplit", "WinSeparator",
  "StatusLine", "StatusLineNC",
  "TabLineFill", "MsgArea",
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

--- Apply transparency over all UI elements
function M.enable()
  if _G.Bundle then _G.Bundle.state.transparent = true end
  for _, g in ipairs(all_groups) do
    vim.api.nvim_set_hl(0, g, { bg = "none" })
  end
  logger.info("[Transparency Engine] Enabled full UI transparency")
end

--- Disable transparency and restore solid colorscheme backgrounds
function M.disable()
  if _G.Bundle then _G.Bundle.state.transparent = false end
  local scheme = (_G.Bundle and _G.Bundle.state and _G.Bundle.state.colorscheme) or vim.g.colors_name or "catppuccin-mocha"
  pcall(vim.cmd.colorscheme, scheme)
  logger.info(string.format("[Transparency Engine] Disabled transparency, restored colorscheme '%s'", scheme))
end

--- Toggle transparency state on or off & persist to disk
function M.toggle()
  local is_trans = _G.Bundle and _G.Bundle.state and _G.Bundle.state.transparent
  if is_trans then
    M.disable()
    if vim.notify then vim.notify("Transparency OFF (Solid Backgrounds Restored)", vim.log.levels.INFO) end
  else
    M.enable()
    if vim.notify then vim.notify("Transparency ON (All UI Backgrounds Cleared)", vim.log.levels.INFO) end
  end

  if _G.Bundle then
    _G.Bundle:save_state()
  end
end

return {
  id = "transparency",
  phase = dag_lib.Phases.POST,
  deps = { "colorscheme" },
  exec = function()
    -- Initialize state from Bundle.state (loaded from bundle_state.json)
    local state = _G.Bundle and _G.Bundle.state or {}
    local is_transparent = state.transparent ~= false

    -- User Commands
    vim.api.nvim_create_user_command("ToggleTransparency", function()
      M.toggle()
    end, { desc = "Toggle full UI transparency on/off" })

    vim.api.nvim_create_user_command("ApplyTransparency", function()
      M.enable()
      if _G.Bundle then _G.Bundle:save_state() end
    end, { desc = "Apply transparency over current colorscheme" })

    -- Auto-reapply transparency whenever colorscheme changes
    local augroup = vim.api.nvim_create_augroup("DAGTransparency", { clear = true })
    vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
      group = augroup,
      callback = function()
        if _G.Bundle and _G.Bundle.state and _G.Bundle.state.transparent ~= false then
          M.enable()
        end
      end,
    })

    if is_transparent then
      M.enable()
    end
  end,
}
