--- All-or-Nothing Transparency Engine
--- Toggles full UI transparency (including NvimTree, Telescope, Floats & Statuslines)
--- and automatically re-applies transparency over any selected ColorScheme.

local dag_lib = require("library.dag")
local logger = require("library.logger")

local M = {}

M.is_transparent = true

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
  M.is_transparent = true
  for _, g in ipairs(all_groups) do
    vim.api.nvim_set_hl(0, g, { bg = "none" })
  end
  logger.info("[Transparency Engine] Enabled full UI transparency")
end

--- Disable transparency and restore solid colorscheme backgrounds
function M.disable()
  M.is_transparent = false
  local scheme = vim.g.colors_name or "catppuccin-mocha"
  pcall(vim.cmd.colorscheme, scheme)
  logger.info(string.format("[Transparency Engine] Disabled transparency, restored colorscheme '%s'", scheme))
end

--- Toggle transparency state on or off
function M.toggle()
  if M.is_transparent then
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
    -- Initialize state from settings
    local settings = _G.Bundle and _G.Bundle.settings or {}
    if settings.transparent == false then
      M.is_transparent = false
    else
      M.is_transparent = true
    end

    -- User Commands
    vim.api.nvim_create_user_command("ToggleTransparency", function()
      M.toggle()
    end, { desc = "Toggle full UI transparency on/off" })

    vim.api.nvim_create_user_command("ApplyTransparency", function()
      M.enable()
    end, { desc = "Apply transparency over current colorscheme" })

    -- Auto-reapply transparency whenever colorscheme changes
    local augroup = vim.api.nvim_create_augroup("DAGTransparency", { clear = true })
    vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
      group = augroup,
      callback = function()
        if M.is_transparent then
          M.enable()
        end
      end,
    })

    if M.is_transparent then
      M.enable()
    end
  end,
}
