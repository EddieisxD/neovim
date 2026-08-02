--- All-or-Nothing Transparency Engine
--- Toggles full UI transparency (including NvimTree, Telescope, Floats, Fidget, Statuslines & Top Bufferline)
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
  "TabLine", "TabLineFill", "TabLineSel", "MsgArea",
  -- Top Bufferline Highlights
  "lualine_c_normal", "lualine_a_buffers_active", "lualine_b_buffers_inactive",
  "lualine_c_buffers_inactive", "lualine_a_buffers_inactive",
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

--- Apply transparency over all UI elements
function M.enable()
  if _G.Bundle then
    _G.Bundle.state.transparent = true
    _G.Bundle:save_state()
  end
  for _, g in ipairs(all_groups) do
    vim.api.nvim_set_hl(0, g, { bg = "none" })
  end
  vim.api.nvim_set_hl(0, "MsgArea", { bg = "none" })
  logger.info("[Transparency Engine] Enabled full UI transparency")
end

--- Disable transparency and restore solid colorscheme backgrounds
function M.disable()
  if _G.Bundle then
    _G.Bundle.state.transparent = false
    _G.Bundle:save_state()
  end

  -- Clear namespace 0 overrides on all targeted groups so colorscheme background is cleanly re-populated
  for _, g in ipairs(all_groups) do
    pcall(vim.cmd, "hi clear " .. g)
  end

  local scheme = (_G.Bundle and _G.Bundle.state and _G.Bundle.state.colorscheme) or vim.g.colors_name or "catppuccin-mocha"

  local ok_cs, cs_mod = pcall(require, "modules.plugins.colorscheme")
  if ok_cs and cs_mod.api and type(cs_mod.api.set_colorscheme) == "function" then
    cs_mod.api.set_colorscheme(scheme)
  else
    pcall(vim.cmd.colorscheme, scheme)
  end

  vim.api.nvim_set_hl(0, "MsgArea", { link = "Normal" })
  logger.info(string.format("[Transparency Engine] Disabled transparency, restored solid colorscheme '%s'", scheme))
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
    -- User Commands
    vim.api.nvim_create_user_command("ToggleTransparency", function()
      M.toggle()
    end, { desc = "Toggle full UI transparency on/off" })

    vim.api.nvim_create_user_command("ApplyTransparency", function()
      M.enable()
    end, { desc = "Apply transparency over current colorscheme" })

    -- Auto-reapply transparency whenever colorscheme changes
    local augroup = vim.api.nvim_create_augroup("DAGTransparency", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = augroup,
      callback = function()
        if _G.Bundle and _G.Bundle.state and _G.Bundle.state.transparent == true then
          M.enable()
        end
      end,
    })

    -- Initialize transparency from Bundle.state
    local state = _G.Bundle and _G.Bundle.state or {}
    if state.transparent == true then
      M.enable()
    else
      M.disable()
    end
  end,
}
