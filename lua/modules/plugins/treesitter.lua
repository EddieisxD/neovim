--- Treesitter Module Spec
--- Dual-mode syntax highlighting, foldexpr, indentexpr, auto-installer, and textobjects.
--- Sourced from wrapper_modules pattern with UI filetype ignoring to prevent unsupported language warnings.

local dag_lib = require("library.dag")

local ignored_filetypes = {
  cmd = true,
  dialog = true,
  msg = true,
  pager = true,
  fidget = true,
  text = true,
  lazy = true,
  ["blink-cmp-menu"] = true,
  ["blink-cmp-documentation"] = true,
  ["dap-repl"] = true,
  dapui_console = true,
  dapui_scopes = true,
  dapui_breakpoints = true,
  dapui_stacks = true,
  dapui_watches = true,
  dapui_hover = true,
  NvimTree = true,
  TelescopePrompt = true,
  TelescopeResults = true,
  help = true,
  nofile = true,
  prompt = true,
  quickfix = true,
}

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
          local ok = pcall(vim.treesitter.start, buf, language)
          if not ok then return false end
          vim.wo[0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.wo[0].foldmethod = "expr"
          vim.o.foldlevel = 99
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          return true
        end

        local augroup = vim.api.nvim_create_augroup("DAGTreesitterAutoAttach", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
          group = augroup,
          callback = function(args)
            local buf, filetype = args.buf, args.match
            if not filetype or filetype == "" or ignored_filetypes[filetype] then return end

            local language = (vim.treesitter.language and vim.treesitter.language.get_lang and vim.treesitter.language.get_lang(filetype)) or filetype

            if not treesitter_try_attach(buf, language) then
              -- Strict check for tree-sitter CLI executable inside callback
              local has_ts_cli = (vim.fn.executable("tree-sitter") == 1)
              local ok_ts_mod, ts_mod = pcall(require, "nvim-treesitter")

              if has_ts_cli and ok_ts_mod and type(ts_mod.install) == "function" then
                pcall(function()
                  local install_task = ts_mod.install(language)
                  if install_task and type(install_task.await) == "function" then
                    install_task:await(function()
                      treesitter_try_attach(buf, language)
                    end)
                  end
                end)
              elseif not has_ts_cli then
                vim.notify_once(
                  string.format("Treesitter parser for '%s' is not installed. Install 'tree-sitter-cli' to enable auto-installation.", language),
                  vim.log.levels.WARN
                )
              end
            end
          end,
        })
      end,
    },
  },
  exec = function() end,
}
