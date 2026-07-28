--- Curated Colorscheme Collection Spec
--- Supports: catppuccin, oxocarbon, carbonfox (nightfox), kanagawa, gruvbox-material, vague, oldworld
--- Loads active theme from Bundle.state (persisted cross-session in bundle_state.json)
--- Dynamically eager-loads active theme (lazy = false, priority = 1000) while lazy-loading
--- all non-active colorschemes (lazy = true) with explicit colorscheme trigger registration.

local dag_lib = require("library.dag")

local state = _G.Bundle and _G.Bundle.state or {}
local defaults = _G.Bundle and _G.Bundle.defaults or {}
local settings = _G.Bundle and _G.Bundle.settings or {}
local target_theme = state.colorscheme or settings.colorscheme or defaults.colorscheme or "catppuccin-mocha"

local theme_to_plugin = {
  ["catppuccin"] = "catppuccin",
  ["catppuccin-mocha"] = "catppuccin",
  ["catppuccin-macchiato"] = "catppuccin",
  ["catppuccin-frappe"] = "catppuccin",
  ["catppuccin-latte"] = "catppuccin",
  ["oxocarbon"] = "oxocarbon",
  ["nightfox"] = "nightfox",
  ["carbonfox"] = "nightfox",
  ["terafox"] = "nightfox",
  ["nordfox"] = "nightfox",
  ["duskfox"] = "nightfox",
  ["dayfox"] = "nightfox",
  ["dawnfox"] = "nightfox",
  ["kanagawa"] = "kanagawa",
  ["kanagawa-wave"] = "kanagawa",
  ["kanagawa-dragon"] = "kanagawa",
  ["kanagawa-lotus"] = "kanagawa",
  ["gruvbox-material"] = "gruvbox-material",
  ["vague"] = "vague",
  ["oldworld"] = "oldworld",
}

local active_plugin_id = theme_to_plugin[target_theme] or "catppuccin"

local function apply_active_colorscheme()
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
      colorschemes = { "catppuccin", "catppuccin-mocha", "catppuccin-macchiato", "catppuccin-frappe", "catppuccin-latte" },
      lazy = (active_plugin_id ~= "catppuccin"),
      priority = (active_plugin_id == "catppuccin") and 1000 or nil,
    },
    -- Oxocarbon
    {
      name = "nyoom-engineering/oxocarbon.nvim",
      nix_name = "oxocarbon-nvim",
      id = "oxocarbon",
      colorschemes = { "oxocarbon" },
      lazy = (active_plugin_id ~= "oxocarbon"),
      priority = (active_plugin_id == "oxocarbon") and 1000 or nil,
    },
    -- Nightfox / Carbonfox
    {
      name = "EdenEast/nightfox.nvim",
      nix_name = "nightfox-nvim",
      id = "nightfox",
      colorschemes = { "nightfox", "carbonfox", "terafox", "nordfox", "duskfox", "dayfox", "dawnfox" },
      lazy = (active_plugin_id ~= "nightfox"),
      priority = (active_plugin_id == "nightfox") and 1000 or nil,
    },
    -- Kanagawa
    {
      name = "rebelot/kanagawa.nvim",
      nix_name = "kanagawa-nvim",
      id = "kanagawa",
      colorschemes = { "kanagawa", "kanagawa-wave", "kanagawa-dragon", "kanagawa-lotus" },
      lazy = (active_plugin_id ~= "kanagawa"),
      priority = (active_plugin_id == "kanagawa") and 1000 or nil,
    },
    -- Gruvbox Material
    {
      name = "sainnhe/gruvbox-material",
      nix_name = "gruvbox-material",
      id = "gruvbox-material",
      colorschemes = { "gruvbox-material" },
      lazy = (active_plugin_id ~= "gruvbox-material"),
      priority = (active_plugin_id == "gruvbox-material") and 1000 or nil,
    },
    -- Vague
    {
      name = "vague2k/vague.nvim",
      nix_name = "vague-nvim",
      id = "vague",
      colorschemes = { "vague" },
      lazy = (active_plugin_id ~= "vague"),
      priority = (active_plugin_id == "vague") and 1000 or nil,
    },
    -- Oldworld
    {
      name = "dgox16/oldworld.nvim",
      nix_name = "oldworld-nvim",
      id = "oldworld",
      colorschemes = { "oldworld" },
      lazy = (active_plugin_id ~= "oldworld"),
      priority = (active_plugin_id == "oldworld") and 1000 or nil,
    },
  },
  exec = function()
    apply_active_colorscheme()

    -- Complete list of all installed theme variants for tab-autocompletion
    local all_installed_themes = {}
    for theme, _ in pairs(theme_to_plugin) do
      table.insert(all_installed_themes, theme)
    end
    table.sort(all_installed_themes)

    local function colorscheme_complete(arg_lead, _, _)
      local matches = {}
      local lead = arg_lead:lower()
      for _, theme in ipairs(all_installed_themes) do
        if theme:lower():find(lead, 1, true) then
          table.insert(matches, theme)
        end
      end
      return matches
    end

    -- Create user commands :Colorscheme and :Theme with custom completion across all themes
    local cmd_opts = {
      nargs = 1,
      complete = colorscheme_complete,
      desc = "Switch colorscheme with complete autocompletion across all installed theme variants",
    }

    local function handle_cmd(opts)
      local choice = opts.args
      if choice and #choice > 0 then
        local ok, err = pcall(vim.cmd.colorscheme, choice)
        if not ok then
          vim.notify("Failed to set colorscheme: " .. tostring(err), vim.log.levels.ERROR)
        end
      end
    end

    vim.api.nvim_create_user_command("Colorscheme", handle_cmd, cmd_opts)
    vim.api.nvim_create_user_command("Theme", handle_cmd, cmd_opts)

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
