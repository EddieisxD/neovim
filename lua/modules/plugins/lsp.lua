--- LSP Module Spec
local dag_lib = require("library.dag")

return {
  id = "lsp",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options", "keymaps" },
  specs = {
    {
      name = "neovim/nvim-lspconfig",
      id = "nvim-lspconfig",
      event = { "BufReadPre", "BufNewFile" },
      config = function()
        local ok, lspconfig = pcall(require, "lspconfig")
        if ok then
          if vim.fn.executable("lua-language-server") == 1 then
            lspconfig.lua_ls.setup({})
          end
          if vim.fn.executable("nil") == 1 then
            lspconfig.nil_ls.setup({})
          end
        end
      end,
    },
  },
  exec = function() end,
}
