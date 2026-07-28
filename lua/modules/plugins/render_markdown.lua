--- Render Markdown Plugin Spec (Sourced from ~/.config/nvim)
local dag_lib = require("library.dag")

local function apply_markdown_theme()
  vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "none" })
  vim.api.nvim_set_hl(0, "RenderMarkdownCodeBorder", { bg = "none" })
  vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { bg = "none" })

  vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = "#ff6b6b" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = "#ffa94d" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = "#ffd43b" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH4", { fg = "#69db7c" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH5", { fg = "#74c0fc" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH6", { fg = "#da77f2" })

  vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "#1a1111" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "#1a1510" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "#1a1a10" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { bg = "#101a10" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { bg = "#10101a" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { bg = "#15101a" })
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
