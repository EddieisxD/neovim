--- Treesitter & Textobjects Module Spec
--- Dual-mode syntax highlighting, foldexpr, indentexpr, auto-installer, and textobjects.
--- Sourced from wrapper_modules pattern for zero-conflict Nix + Traditional compatibility.

local dag_lib = require("library.dag")

return {
  id = "treesitter",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "nvim-treesitter/nvim-treesitter",
      id = "nvim-treesitter",
      nix_name = "nvim-treesitter-with-all-grammars",
      deps = { "nvim-treesitter/nvim-treesitter-textobjects" },
      event = { "BufReadPost", "BufNewFile" },
      cmd = { "TSUpdate", "TSInstall" },
      config = function()
        local ok_ts, ts = pcall(require, "nvim-treesitter.configs")
        if ok_ts then
          ts.setup({
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
          })
        end

        local function treesitter_try_attach(buf, language)
          if not (vim.treesitter.language and vim.treesitter.language.add) or not vim.treesitter.language.add(language) then
            return false
          end

          pcall(vim.treesitter.start, buf, language)
          vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.wo.foldmethod = "expr"
          vim.o.foldlevel = 99
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          return true
        end

        local installable_parsers = {}
        local ok_ts_mod, ts_mod = pcall(require, "nvim-treesitter")
        if ok_ts_mod and type(ts_mod.get_available) == "function" then
          installable_parsers = ts_mod.get_available()
        end

        local augroup = vim.api.nvim_create_augroup("DAGTreesitterAutoAttach", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
          group = augroup,
          callback = function(args)
            local buf, filetype = args.buf, args.match
            if not filetype or filetype == "" then return end

            local language = (vim.treesitter.language and vim.treesitter.language.get_lang and vim.treesitter.language.get_lang(filetype)) or filetype

            if not treesitter_try_attach(buf, language) then
              if ok_ts_mod and vim.tbl_contains(installable_parsers, language) and type(ts_mod.install) == "function" then
                pcall(function()
                  ts_mod.install(language):await(function()
                    treesitter_try_attach(buf, language)
                  end)
                end)
              end
            end
          end,
        })
      end,
    },
  },
  exec = function() end,
}
