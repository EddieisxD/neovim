--- Render Markdown Plugin Spec
--- Consumes default highlight color palette from Bundle.defaults.render_markdown.

local dag_lib = require("library.dag")

local function apply_markdown_theme()
  local defaults = _G.Bundle and _G.Bundle.defaults and _G.Bundle.defaults.render_markdown or {}

  vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = defaults.code_bg or "none" })
  vim.api.nvim_set_hl(0, "RenderMarkdownCodeBorder", { bg = defaults.code_bg or "none" })
  vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { bg = defaults.code_bg or "none" })

  local h1 = defaults.h1 or { fg = "#ff6b6b", bg = "#1a1111" }
  local h2 = defaults.h2 or { fg = "#ffa94d", bg = "#1a1510" }
  local h3 = defaults.h3 or { fg = "#ffd43b", bg = "#1a1a10" }
  local h4 = defaults.h4 or { fg = "#69db7c", bg = "#101a10" }
  local h5 = defaults.h5 or { fg = "#74c0fc", bg = "#10101a" }
  local h6 = defaults.h6 or { fg = "#da77f2", bg = "#15101a" }

  vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = h1.fg })
  vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = h2.fg })
  vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = h3.fg })
  vim.api.nvim_set_hl(0, "RenderMarkdownH4", { fg = h4.fg })
  vim.api.nvim_set_hl(0, "RenderMarkdownH5", { fg = h5.fg })
  vim.api.nvim_set_hl(0, "RenderMarkdownH6", { fg = h6.fg })

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
  deps = { "options", "treesitter" },
  specs = {
    {
      name = "MeanderingProgrammer/render-markdown.nvim",
      id = "render-markdown",
      deps = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
      ft = { "markdown", "norg", "rmd", "org" },
      opts = {
        enabled_filetypes = { "markdown", "org", "norg", "rmd" },
        preset = "obsidian",
        acknowledge_conflicts = true,
        debounce = 30,
        heading = { border = false },
        bullet = { icons = { "●", "○", "◉", "◎" } },
        anti_conceal = {
          ignore = {
            code_background = true,
            indent = true,
            sign = true,
            virtual_lines = true,
            bullet = true,
            head_icon = true,
            head_background = true,
            head_border = true,
          },
        },
      },
      config = function(_, opts)
        local ok, rm = pcall(require, "render-markdown")
        if ok then
          rm.setup(opts or {})
        end
        apply_markdown_theme()
      end,
    },
  },
  exec = function() end,
}
