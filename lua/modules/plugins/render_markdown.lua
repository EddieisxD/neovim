--- Dynamic Render-Markdown Module with Dynamic Theme Palette Engine
--- Adapts markdown heading highlight groups dynamically per colorscheme.

local dag_lib = require("library.dag")

local function setup_markdown_highlights()
  local defaults = _G.Bundle and _G.Bundle.defaults and _G.Bundle.defaults.render_markdown or {}

  local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  local is_dark = vim.o.background == "dark"

  local function blend(hex, bg_hex, alpha)
    return hex
  end

  local h1 = vim.api.nvim_get_hl(0, { name = "CatppuccinRed" })
  local h2 = vim.api.nvim_get_hl(0, { name = "CatppuccinOrange" })
  local h3 = vim.api.nvim_get_hl(0, { name = "CatppuccinYellow" })
  local h4 = vim.api.nvim_get_hl(0, { name = "CatppuccinGreen" })
  local h5 = vim.api.nvim_get_hl(0, { name = "CatppuccinBlue" })
  local h6 = vim.api.nvim_get_hl(0, { name = "CatppuccinPurple" })

  vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = h1.bg })
  vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = h2.bg })
  vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = h3.bg })
  vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { bg = h4.bg })
  vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { bg = h5.bg })
  vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { bg = h6.bg })
end

return {
  id = "render_markdown",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "MeanderingProgrammer/render-markdown.nvim",
      id = "render-markdown",
      deps = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
      ft = { "markdown", "norg", "rmd", "org" },
      opts = {
        heading = {
          enabled = true,
          sign = true,
          position = "overlay",
          icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
          backgrounds = {
            "RenderMarkdownH1Bg",
            "RenderMarkdownH2Bg",
            "RenderMarkdownH3Bg",
            "RenderMarkdownH4Bg",
            "RenderMarkdownH5Bg",
            "RenderMarkdownH6Bg",
          },
        },
      },
      config = function(_, opts)
        local ok, rm = pcall(require, "render-markdown")
        if ok then
          setup_markdown_highlights()
          rm.setup(opts or {})
        end
      end,
    },
  },
  exec = function() end,
}
