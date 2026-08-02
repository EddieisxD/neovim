--- Curated Colorscheme Suite Module
--- Manages Catppuccin, Kanagawa, Nightfox, Gruvbox-Material, Oxocarbon, Vague, and Oldworld.

local dag_lib = require("library.dag")
local logger = require("library.logger")

local M = {}

--- Active default theme name
M.default_scheme = "catppuccin-mocha"

--- Curated list of downloaded themes
M.curated_themes = {
  "catppuccin",
  "catppuccin-mocha",
  "catppuccin-macchiato",
  "catppuccin-frappe",
  "catppuccin-latte",
  "kanagawa",
  "kanagawa-wave",
  "kanagawa-dragon",
  "kanagawa-lotus",
  "nightfox",
  "nordfox",
  "duskfox",
  "terafox",
  "carbonfox",
  "gruvbox-material",
  "oxocarbon",
  "vague",
  "oldworld",
}

--- Safely apply a colorscheme with fallback to default
---@param name string Colorscheme name
function M.set_colorscheme(name)
  name = (name and name ~= "") and name or M.default_scheme

  local is_trans = _G.Bundle and _G.Bundle.state and _G.Bundle.state.transparent == true
  local ok = false

  -- Catppuccin Flavours
  if name:match("^catppuccin") then
    local ok_cat, cat = pcall(require, "catppuccin")
    if ok_cat then
      local flavour = name:gsub("^catppuccin%-", "")
      if flavour == "catppuccin" or flavour == "" then flavour = "mocha" end
      pcall(cat.setup, {
        flavour = flavour,
        transparent_background = is_trans,
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          fidget = true,
          lualine = true,
          native_lsp = { enabled = true },
        },
      })
      pcall(cat.load, flavour)
      vim.g.colors_name = name
      ok = true
    end
  end

  -- Fallback to standard vim.cmd.colorscheme if not loaded via catppuccin API
  if not ok then
    ok = pcall(vim.cmd.colorscheme, name)
    if ok then
      vim.g.colors_name = name
    end
  end

  if not ok then
    logger.warn(string.format("[Colorscheme Module] Theme '%s' failed to load, falling back to '%s'", name, M.default_scheme))
    pcall(vim.cmd.colorscheme, M.default_scheme)
    vim.g.colors_name = M.default_scheme
  end

  -- Emit ColorScheme event so transparency and lualine update reactively
  pcall(vim.cmd, "doautocmd ColorScheme " .. vim.g.colors_name)

  logger.info(string.format("[Colorscheme Module] Applied theme '%s'", vim.g.colors_name))
  if _G.Bundle then
    _G.Bundle.state.colorscheme = vim.g.colors_name
    _G.Bundle:save_state()
  end
  return true
end

return {
  id = "colorscheme",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "catppuccin/nvim",
      id = "catppuccin",
      nix_name = "catppuccin-nvim",
      lazy = false,
      priority = 1000,
      opts = {
        flavour = "mocha",
        transparent_background = false,
        term_colors = true,
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          fidget = true,
          lualine = true,
          native_lsp = {
            enabled = true,
            underlines = {
              errors = { "undercurl" },
              hints = { "undercurl" },
              warnings = { "undercurl" },
              information = { "undercurl" },
            },
          },
        },
      },
      config = function(_, opts)
        local ok, catppuccin = pcall(require, "catppuccin")
        if ok then
          local is_trans = _G.Bundle and _G.Bundle.state and _G.Bundle.state.transparent == true
          opts.transparent_background = is_trans
          catppuccin.setup(opts)
        end
        local state = _G.Bundle and _G.Bundle.state or {}
        local scheme = state.colorscheme or M.default_scheme
        M.set_colorscheme(scheme)
      end,
    },
    { name = "sainnhe/gruvbox-material", id = "gruvbox-material", nix_name = "gruvbox-material", lazy = true },
    { name = "rebelot/kanagawa.nvim", id = "kanagawa", nix_name = "kanagawa-nvim", lazy = true },
    { name = "EdenEast/nightfox.nvim", id = "nightfox", nix_name = "nightfox-nvim", lazy = true },
    { name = "dgox16/oldworld.nvim", id = "oldworld", nix_name = "oldworld-nvim", lazy = true },
    { name = "nyoom-engineering/oxocarbon.nvim", id = "oxocarbon", nix_name = "oxocarbon-nvim", lazy = true },
    { name = "vague26/vague.nvim", id = "vague", nix_name = "vague-nvim", lazy = true },
  },

  exec = function()
    -- Custom completion function for :Theme and :Colorscheme that prioritizes curated downloaded themes
    local function theme_completion(arg_lead, _, _)
      local matches = {}
      for _, t in ipairs(M.curated_themes) do
        if t:find(arg_lead, 1, true) == 1 then
          table.insert(matches, t)
        end
      end
      return matches
    end

    local function theme_command(opts)
      local name = opts.args ~= "" and opts.args or M.default_scheme
      M.set_colorscheme(name)
    end

    vim.api.nvim_create_user_command("Theme", theme_command, {
      nargs = "?",
      complete = theme_completion,
      desc = "Apply curated colorscheme / theme",
    })

    vim.api.nvim_create_user_command("Colorscheme", theme_command, {
      nargs = "?",
      complete = theme_completion,
      desc = "Apply curated colorscheme / theme",
    })

    vim.cmd("cabbrev theme Theme")

    -- Expose API on Bundle bridge
    if _G.Bundle and _G.Bundle.bridge then
      _G.Bundle.bridge.set_colorscheme = M.set_colorscheme
    end
  end,
  api = M,
}
