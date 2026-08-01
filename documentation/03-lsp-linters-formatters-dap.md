# 03 Language Tooling: LSP, Formatters, Linters & Debugger Engine

This document details the architecture of our **Mason-Free Environment Sourcing Engine** and the complete integration of Language Servers (LSP), Formatters (`conform.nvim`), Linters (`nvim-lint`), and Debuggers (`nvim-dap`).

---

## 1. Mason-Free Dynamic Environment Sourcing Engine

### 🔍 Why Mason-Free under NixOS?
Mason is designed for traditional operating systems to imperatively download pre-compiled x86_64 binaries into `~/.local/share/nvim/mason/bin`. Under NixOS:
1. Dynamically linked binaries downloaded by Mason fail with `ld-linux.so` ELF header missing loader errors.
2. Mason violates NixOS's declarative reproducibility model.

### 📐 Technical Solution ([`lua/modules/plugins/lsp.lua`](file:///home/addy/.config/nvim/lua/modules/plugins/lsp.lua))
Our engine dynamically scans `$PATH` for active language tooling binaries. Whether binaries come from a Nix Flake devShell (`nix develop`), `direnv`, NixOS system packages, or local PATHs, Neovim discovers them automatically on startup:

```lua
local known_servers = {
  { name = "nil_ls",        bin = "nil",                       cmd = { "nil" },                       ft = { "nix" } },
  { name = "nixd",          bin = "nixd",                      cmd = { "nixd" },                      ft = { "nix" } },
  { name = "lua_ls",        bin = "lua-language-server",       cmd = { "lua-language-server" },       ft = { "lua" } },
  { name = "pyright",       bin = "pyright-langserver",        cmd = { "pyright-langserver", "--stdio" }, ft = { "python" } },
  { name = "pylsp",         bin = "pylsp",                     cmd = { "pylsp" },                     ft = { "python" } },
  { name = "gopls",         bin = "gopls",                     cmd = { "gopls" },                     ft = { "go", "gomod" } },
  { name = "rust_analyzer", bin = "rust-analyzer",             cmd = { "rust-analyzer" },             ft = { "rust" } },
  { name = "ts_ls",         bin = "typescript-language-server", cmd = { "typescript-language-server", "--stdio" }, ft = { "typescript", "javascript" } },
  { name = "clangd",        bin = "clangd",                    cmd = { "clangd" },                    ft = { "c", "cpp" } },
  { name = "bashls",        bin = "bash-language-server",      cmd = { "bash-language-server", "start" }, ft = { "sh", "bash" } },
}

local function scan_and_enable_servers()
  for _, s in ipairs(known_servers) do
    if not active_servers[s.name] and vim.fn.executable(s.bin) == 1 then
      active_servers[s.name] = true
      vim.lsp.config(s.name, {
        cmd = s.cmd or { s.bin },
        filetypes = s.ft,
        settings = s.settings or {},
      })
      vim.lsp.enable(s.name)
    end
  end
end
```

#### RPC `--stdio` Gotcha Resolution:
- Servers like `pyright-langserver`, `typescript-language-server`, `yaml-language-server` require `--stdio` in their command array.
- Servers like `nixd`, `nil`, `lua-language-server`, `clangd` communicate over stdio natively and **reject `--stdio`** with exit code 1.
- Specifying explicit `cmd` arrays per server prevents LSP crashes!

---

## 2. Asynchronous Formatter Engine (`conform.nvim`)

Located in [`lua/modules/plugins/formatter.lua`](file:///home/addy/.config/nvim/lua/modules/plugins/formatter.lua).

### Configuration & Binary Mapping
```lua
local formatters_by_ft = {
  nix = { "nixfmt", "alejandra" },
  lua = { "stylua" },
  sh = { "shfmt" },
  bash = { "shfmt" },
  python = { "black", "ruff" },
  rust = { "rustfmt" },
  go = { "gofmt" },
  javascript = { "prettier" },
  typescript = { "prettier" },
  c = { "clang-format" },
  cpp = { "clang-format" },
}
```

### Commands & Controls
- **`<leader>fm`**: Manually format the current buffer asynchronously.
- **`:formatter format`**: Format buffer.
- **`:formatter info`**: Show active formatters on `$PATH` for active filetype.
- **`:formatter toggle`**: Toggle format-on-save preference.

---

## 3. Asynchronous Linter Engine (`nvim-lint`)

Located in [`lua/modules/plugins/linter.lua`](file:///home/addy/.config/nvim/lua/modules/plugins/linter.lua).

### Architecture & Diagnostic Namespace
`nvim-lint` runs linters (`statix`, `shellcheck`, `luacheck`, `flake8`, `eslint`) in non-blocking background sub-processes via `vim.system`. It parses stdout/stderr into Lua tables and registers diagnostics under dedicated namespaces (e.g. `statix` or `shellcheck`).

### Commands & Controls
- **`:linter lint`** or **`:Lint`**: Trigger asynchronous linting on current buffer.
- **`:linter info`**: List active `$PATH` linters for current filetype.
- **`:linter toggle`**: Toggle auto-linting on/off.

---

## 4. Debugger Engine (`nvim-dap` + `nvim-dap-ui`)

Located in [`lua/modules/plugins/dap.lua`](file:///home/addy/.config/nvim/lua/modules/plugins/dap.lua).

### Keymaps & Commands
- **`<leader>db`**: Toggle DAP Breakpoint (`󰏤`).
- **`<leader>dc`**: Start or Continue DAP Debugger.
- **`<leader>du`**: Toggle visual DAP UI panels (Variables, Stacks, Breakpoints, Watches).
- **`:dap info`**: Display current DAP debug session status.
