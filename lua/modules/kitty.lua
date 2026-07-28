--- Kitty Terminal Remote Control Integration
--- Checks if running under Kitty terminal with remote control enabled,
--- removes window padding on startup and restores default padding on exit.

local dag_lib = require("library.dag")
local logger = require("library.logger")

local function is_kitty()
  return os.getenv("KITTY_WINDOW_ID") ~= nil or os.getenv("TERM") == "xterm-kitty"
end

local function set_kitty_padding(padding_val)
  if not is_kitty() then return end

  -- Execute kitty remote control command
  local out = vim.fn.system({ "kitty", "@", "set-spacing", "padding=" .. tostring(padding_val) })
  if vim.v.shell_error == 0 then
    logger.info(string.format("[Kitty Integration] Set Kitty window padding to '%s'", tostring(padding_val)))
    return true
  else
    logger.debug("[Kitty Integration] Kitty remote control disabled or socket unreachable")
    return false
  end
end

return {
  id = "kitty",
  phase = dag_lib.Phases.SETUP,
  deps = { "options" },
  exec = function()
    if not is_kitty() then return end

    -- Remove padding on startup
    set_kitty_padding(0)

    -- Restore default padding on exit
    local augroup = vim.api.nvim_create_augroup("KittyTerminalPadding", { clear = true })
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = augroup,
      callback = function()
        set_kitty_padding("default")
      end,
    })
  end,
}
