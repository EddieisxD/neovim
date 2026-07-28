--- Dynamic Environment-Sourced LSP Module
--- Eliminates Mason dependency by dynamically discovering LSP binaries on $PATH
--- (sourced from nix-shell, nix develop, direnv, NixOS, or system shells).

local dag_lib = require("library.dag")
local logger = require("library.logger")

--- Registry of known Language Servers and their executable names & settings
local known_servers = {
  {
    name = "nil_ls",
    bin = "nil",
    ft = { "nix" },
    settings = {
      ["nil"] = {
        formatting = { command = { "nixfmt" } },
        nixos = {
          options = {
            expr = "null", -- Suppresses NixOS option eval error when not in a system configuration
          },
        },
      },
    },
  },
  { name = "nixd",          bin = "nixd",                      ft = { "nix" } },
  { name = "lua_ls",        bin = "lua-language-server",       ft = { "lua" } },
  { name = "pyright",       bin = "pyright-langserver",        ft = { "python" } },
  { name = "pylsp",         bin = "pylsp",                     ft = { "python" } },
  { name = "gopls",         bin = "gopls",                     ft = { "go", "gomod" } },
  { name = "rust_analyzer", bin = "rust-analyzer",             ft = { "rust" } },
  { name = "ts_ls",         bin = "typescript-language-server", ft = { "typescript", "javascript", "typescriptreact", "javascriptreact" } },
  { name = "clangd",        bin = "clangd",                    ft = { "c", "cpp", "objc", "objcpp" } },
  { name = "bashls",        bin = "bash-language-server",      ft = { "sh", "bash" } },
  { name = "taplo",         bin = "taplo",                     ft = { "toml" } },
  { name = "yamlls",        bin = "yaml-language-server",      ft = { "yaml", "yml" } },
  { name = "jsonls",        bin = "vscode-json-language-server", ft = { "json", "jsonc" } },
  { name = "zls",           bin = "zls",                       ft = { "zig" } },
}

local active_servers = {}

--- Scan $PATH for available LSP executables and configure them dynamically
local function scan_and_enable_servers()
  local newly_enabled = 0

  for _, s in ipairs(known_servers) do
    if not active_servers[s.name] and vim.fn.executable(s.bin) == 1 then
      active_servers[s.name] = true
      newly_enabled = newly_enabled + 1

      logger.info(string.format("[LSP Environment Engine] Discovered binary '%s' on $PATH for LSP '%s'", s.bin, s.name))

      if vim.lsp and vim.lsp.config then
        -- Neovim 0.11+ Native LSP API
        vim.lsp.config(s.name, {
          cmd = { s.bin, "--stdio" },
          filetypes = s.ft,
          settings = s.settings or {},
        })
        vim.lsp.enable(s.name)
      else
        -- Fallback to nvim-lspconfig
        local ok, lspconfig = pcall(require, "lspconfig")
        if ok and lspconfig[s.name] then
          lspconfig[s.name].setup({
            settings = s.settings or {},
          })
        end
      end
    end
  end

  if newly_enabled > 0 then
    logger.info(string.format("[LSP Environment Engine] Enabled %d new LSP servers from active shell environment", newly_enabled))
  end
end

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
        scan_and_enable_servers()
      end,
    },
  },

  exec = function()
    -- Initial environment scan
    scan_and_enable_servers()

    -- Auto-rescan environment on direnv reload or directory change
    local augroup = vim.api.nvim_create_augroup("LspEnvironmentScanner", { clear = true })
    vim.api.nvim_create_autocmd({ "DirChanged", "BufReadPost" }, {
      group = augroup,
      callback = function()
        scan_and_enable_servers()
      end,
    })
  end,
}
