--- Colorscheme Module Spec
--- Loads active theme from Bundle.state (persisted cross-session in bundle_state.json)
--- and automatically updates Bundle.state when changing colorschemes at runtime.

local dag_lib = require("library.dag")

local function apply_active_colorscheme()
  local state = _G.Bundle and _G.Bundle.state or {}
  local defaults = _G.Bundle and _G.Bundle.defaults or {}
  local settings = _G.Bundle and _G.Bundle.settings or {}

  local target_theme = state.colorscheme or settings.colorscheme or defaults.colorscheme or "catppuccin-mocha"
  pcall(vim.cmd.colorscheme, target_theme)
end

return {
  id = "colorscheme",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "catppuccin/nvim",
      nix_name = "catppuccin-nvim",
      id = "catppuccin",
      lazy = false,
      priority = 1000,
      config = function()
        apply_active_colorscheme()
      end,
    },
  },
  exec = function()
    apply_active_colorscheme()

    -- Automatically listen to ColorScheme events to update Bundle.state & persist to disk
    local augroup = vim.api.nvim_create_augroup("DAGColorSchemeState", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = augroup,
      callback = function(args)
        if _G.Bundle then
          _G.Bundle.state.colorscheme = args.match
          _G.Bundle:save_state()
        end
      end,
    })
  end,
}
