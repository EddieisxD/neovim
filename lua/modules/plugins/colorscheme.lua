--- Curated Colorscheme Collection Spec
--- Supports: catppuccin, oxocarbon, carbonfox (nightfox), kanagawa, gruvbox-material, vague, oldworld
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
    -- Catppuccin
    {
      name = "catppuccin/nvim",
      nix_name = "catppuccin-nvim",
      id = "catppuccin",
      lazy = false,
      priority = 1000,
    },
    -- Oxocarbon
    {
      name = "nyoom-engineering/oxocarbon.nvim",
      nix_name = "oxocarbon-nvim",
      id = "oxocarbon",
      lazy = false,
      priority = 1000,
    },
    -- Nightfox / Carbonfox
    {
      name = "EdenEast/nightfox.nvim",
      nix_name = "nightfox-nvim",
      id = "nightfox",
      lazy = false,
      priority = 1000,
    },
    -- Kanagawa
    {
      name = "rebelot/kanagawa.nvim",
      nix_name = "kanagawa-nvim",
      id = "kanagawa",
      lazy = false,
      priority = 1000,
    },
    -- Gruvbox Material
    {
      name = "sainnhe/gruvbox-material",
      nix_name = "gruvbox-material",
      id = "gruvbox-material",
      lazy = false,
      priority = 1000,
    },
    -- Vague
    {
      name = "vague2k/vague.nvim",
      nix_name = "vague-nvim",
      id = "vague",
      lazy = false,
      priority = 1000,
    },
    -- Oldworld
    {
      name = "dgox16/oldworld.nvim",
      nix_name = "oldworld-nvim",
      id = "oldworld",
      lazy = false,
      priority = 1000,
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
