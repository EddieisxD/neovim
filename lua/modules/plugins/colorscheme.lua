--- Clean Colorscheme Module
--- Keeps Catppuccin Mocha as the sole curated theme with fallback to Neovim default.

local dag_lib = require("library.dag")
local logger = require("library.logger")

local M = {}

--- Active default theme name
M.default_scheme = "catppuccin-mocha"

--- Safely apply a colorscheme with fallback to default
---@param name string Colorscheme name
function M.set_colorscheme(name)
  name = (name and name ~= "") and name or M.default_scheme

  local ok_cat, cat = pcall(require, "catppuccin")
  if ok_cat then
    if name:match("^catppuccin%-") then
      local flavour = name:gsub("^catppuccin%-", "")
      pcall(cat.load, flavour)
    else
      pcall(vim.cmd.colorscheme, name)
    end
  else
    pcall(vim.cmd.colorscheme, name)
  end

  logger.info(string.format("[Colorscheme Module] Applied theme '%s'", name))
  if _G.Bundle then
    _G.Bundle.state.colorscheme = name
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
          catppuccin.setup(opts)
        end
        local state = _G.Bundle and _G.Bundle.state or {}
        local scheme = state.colorscheme or M.default_scheme
        M.set_colorscheme(scheme)
      end,
    },
  },

  exec = function()
    -- User commands for Theme and Colorscheme with full autocompletion (complete = "color")
    local function theme_command(opts)
      local name = opts.args ~= "" and opts.args or M.default_scheme
      M.set_colorscheme(name)
    end

    vim.api.nvim_create_user_command("Theme", theme_command, {
      nargs = "?",
      complete = "color",
      desc = "Apply colorscheme / theme",
    })

    vim.api.nvim_create_user_command("Colorscheme", theme_command, {
      nargs = "?",
      complete = "color",
      desc = "Apply colorscheme / theme",
    })

    vim.cmd("cabbrev theme Theme")

    -- Expose API on Bundle bridge
    if _G.Bundle and _G.Bundle.bridge then
      _G.Bundle.bridge.set_colorscheme = M.set_colorscheme
    end
  end,
  api = M,
}
