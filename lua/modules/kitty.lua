--- Kitty Terminal Remote Control Integration
--- Removes window padding on startup if Kitty remote control is active,
--- applies internal Neovim gutter padding, and restores default Kitty padding on exit.

local dag_lib = require("library.dag")
local logger = require("library.logger")

local function is_kitty()
  return os.getenv("KITTY_WINDOW_ID") ~= nil or os.getenv("TERM") == "xterm-kitty"
end

local function set_kitty_padding(padding_val)
  if not is_kitty() then return false end

  -- Execute kitty remote control set-spacing command
  local cmd = { "kitty", "@", "set-spacing", "padding=" .. tostring(padding_val) }

  -- If KITTY_LISTEN_ON is set, pass --to argument explicitly
  local listen_socket = os.getenv("KITTY_LISTEN_ON")
  if listen_socket and listen_socket ~= "" then
    cmd = { "kitty", "@", "--to=" .. listen_socket, "set-spacing", "padding=" .. tostring(padding_val) }
  end

  local out = vim.fn.system(cmd)
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
  phase = dag_lib.Phases.SETUP + 2,
  deps = { "options" },
  exec = function()
    -- Register on Bundle bridge so any module can trigger terminal padding changes
    if _G.Bundle and _G.Bundle.bridge then
      _G.Bundle.bridge.set_terminal_padding = set_kitty_padding
    end

    if not is_kitty() then return end

    -- Apply Neovim internal gutter padding options
    vim.opt.signcolumn = "yes"
    vim.opt.foldcolumn = "1"

    -- Trigger padding removal on UIEnter / VimEnter when terminal UI is fully rendered
    local augroup = vim.api.nvim_create_augroup("KittyTerminalPadding", { clear = true })
    vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter" }, {
      group = augroup,
      once = true,
      callback = function()
        set_kitty_padding(0)
      end,
    })

    -- Restore default Kitty padding on exit
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = augroup,
      callback = function()
        set_kitty_padding("default")
      end,
    })

    -- Initial attempt
    set_kitty_padding(0)
  end,
}
