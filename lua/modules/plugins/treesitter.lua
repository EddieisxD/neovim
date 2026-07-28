--- Treesitter & Textobjects Module Spec
--- Provides universal syntax highlighting, indenting, and smart textobjects (function/class/parameter selection).

local dag_lib = require("library.dag")

return {
  id = "treesitter",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "nvim-treesitter/nvim-treesitter",
      id = "nvim-treesitter",
      nix_name = "nvim-treesitter",
      deps = { "nvim-treesitter/nvim-treesitter-textobjects" },
      event = { "BufReadPost", "BufNewFile" },
      cmd = { "TSUpdate", "TSInstall" },
      opts = {
        highlight = { enable = true },
        indent = { enable = true },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
            },
          },
        },
      },
      config = function(_, opts)
        local ok, ts = pcall(require, "nvim-treesitter.configs")
        if ok then
          ts.setup(opts or {
            highlight = { enable = true },
            indent = { enable = true },
          })
        end
      end,
    },
  },
  exec = function() end,
}
