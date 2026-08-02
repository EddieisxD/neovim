--- Kitty Terminal Remote Control Integration
--- Applies top padding to create a gap above the top bufferline,
--- applies internal Neovim gutter padding, and restores default Kitty padding/margin on exit.

local dag_lib = require("library.dag")
local logger = require("library.logger")

local function is_kitty()
  return os.getenv("KITTY_WINDOW_ID") ~= nil or os.getenv("TERM") == "xterm-kitty"
end

local function set_kitty_padding(padding_val, margin_val)
  if not is_kitty() then return false end

  local listen_socket = os.getenv("KITTY_LISTEN_ON")

  -- Only invoke kitty @ if KITTY_LISTEN_ON socket exists or remote control is explicitly configured
  if not listen_socket or listen_socket == "" then
    logger.debug("[Kitty Integration] KITTY_LISTEN_ON not set. To enable Kitty padding control, set 'allow_remote_control yes' and 'listen_on unix:/tmp/mykitty' in ~/.config/kitty/kitty.conf")
    return false
  end

  padding_val = tostring(padding_val)
  margin_val = margin_val and tostring(margin_val) or padding_val

  local cmd = { "kitty", "@", "--to=" .. listen_socket, "set-spacing", "padding=" .. padding_val, "margin=" .. margin_val }

  pcall(function()
    vim.system(cmd, { detach = true }, function(res)
      if res and res.code == 0 then
        logger.info(string.format("[Kitty Integration] Set Kitty window padding to '%s' and margin to '%s'", padding_val, margin_val))
      end
    end)
  end)
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

    -- Apply 12px top window padding gap above the top bufferline
    local augroup = vim.api.nvim_create_augroup("KittyTerminalPadding", { clear = true })
    vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter" }, {
      group = augroup,
      once = true,
      callback = function()
        set_kitty_padding(12, 0)
      end,
    })

    -- Restore default Kitty padding & margin on exit
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = augroup,
      callback = function()
        set_kitty_padding("default", "default")
      end,
    })

    -- Initial attempt
    set_kitty_padding(12, 0)
  end,
}
