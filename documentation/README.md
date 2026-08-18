# Neovim Unified Configuration & Architectural Documentation Master Index

Welcome to the unified documentation repository for the **Modular DAG Neovim System**.

This documentation suite consolidates, verifies, and enhances all notes, architectural designs, Nix flake wrappers, Lua API cookbooks, keybindings, and implementation research previously scattered across `~/Projects/neovim` and `~/.config/nvim.bak`.

---

## 📐 Documentation Structure & Sitemap

### 1. [`01-system-architecture.md`](file:///home/addy/.config/nvim/documentation/01-system-architecture.md)
- **Topological DAG Execution Engine**: Kahn's algorithm, 7-phase priority scheduling (`SETUP` $\rightarrow$ `OPTIONS` $\rightarrow$ `KEYMAPS` $\rightarrow$ `AUTOCMDS` $\rightarrow$ `LOADER` $\rightarrow$ `PLUGINS` $\rightarrow$ `POST`), microsecond timing logs, cycle detection.
- **Decoupled 3-Tier Data Architecture**: `Bundle.settings`, `Bundle.defaults`, `Bundle.state` with cross-session JSON persistence (`bundle_state.json`) and isolation modes (`strict`, `tmp`, `flexible`).
- **Metatable Encapsulation & Table Sealing**: `meta.seal()`, `unseal()` bridge, strict immutability guards against typo bugs and silent global pollution.

### 2. [`02-nix-wrapper-and-flake.md`](file:///home/addy/.config/nvim/documentation/02-nix-wrapper-and-flake.md)
- **Pure Nix & Dual-Mode Loader Adapter**: `lze` (Nix `/nix/store` derivation resolution) vs `lazy.nvim` (traditional Git cloning).
- **`wrapperModules` & Nix Flake Architecture**: `module.nix`, `flake.nix`, `runtimePkgs` bundling, `evalModules` deep dive, and Nix path string gotchas (`.;` vs `path;`).
- **BirdeeVim Strategy & Nix Module Responsibilities**: Declarative package bundling without imperative Mason downloads under NixOS.

### 3. [`03-lsp-linters-formatters-dap.md`](file:///home/addy/.config/nvim/documentation/03-lsp-linters-formatters-dap.md)
- **Mason-Free Dynamic Environment Sourcing Engine**: Automatic `$PATH` discovery for LSP binaries (`nixd`, `nil_ls`, `lua_ls`, `pyright`, `gopls`, `rust_analyzer`, `clangd`).
- **LSP Protocol & Configuration**: stdio RPC execution, explicit `cmd` tables, rounded float windows (`border = "rounded"`), and `source = "always"` diagnostic tags.
- **Asynchronous Linter Engine (`nvim-lint`)**: Sub-process execution, namespace isolation (`lint`), `:linter` command suite.
- **Asynchronous Formatter Engine (`conform.nvim`)**: Non-blocking formatting, `:formatter` command suite, `<leader>fm`.
- **Debugger Engine (`nvim-dap` + `nvim-dap-ui`)**: DAP protocol over TCP/sockets, breakpoint signs, `:dap` command suite.

### 4. [`04-gui-terminal-headless.md`](file:///home/addy/.config/nvim/documentation/04-gui-terminal-headless.md)
- **Neovide GUI Integration**: Opacity (`neovide_opacity = 0.65`), padding, fluid cursor VFX (`railgun`), font sizing (`JetBrainsMono Nerd Font:h13`).
- **VSCode / VSCodium Keymap Adapter**: `keymap_registry.bind` semantic registry auto-adapting between TUI Lua functions and VSCode native actions (`workbench.action`).
- **Kitty Remote Terminal Padding Engine**: Asynchronous Kitty remote control (`kitty @ set-spacing padding=0 margin=0`) with `$KITTY_LISTEN_ON` socket guards.
- **Single Instance & Headless Server**: `neovim-remote` (`nvr`), socket multiplexing, and headless execution (`nvim --headless`).

### 5. [`05-vim-api-and-lua-cookbook.md`](file:///home/addy/.config/nvim/documentation/05-vim-api-and-lua-cookbook.md)
- **Neovim Lua API Index**: Comprehensive guide to `vim.api.*`, `vim.fn.*`, `vim.opt.*`, `vim.keymap.set`, `vim.diagnostic.*`, `vim.lsp.*`.
- **Lua Cookbook & Recipes**: Floating window creation, custom autocommands, highlight group overriding, statusline components, options state management.

### 6. [`06-master-keybindings-guide.md`](file:///home/addy/.config/nvim/documentation/06-master-keybindings-guide.md)
- **Unified Master Keybindings Reference**:
  - Vim Motions, Gotos (`gd`, `gD`, `gr`, `gi`), Jumps, Folds, Marks, Paragraphs, Text Objects.
  - Grouped plugin keybinds for LSP (`K`, `<leader>ca`, `<leader>rn`), Diagnostics (`gl`, `]d`, `[d`), Formatter (`<leader>fm`), Linter (`:linter`), Debugger (`<leader>db`, `<leader>dc`, `<leader>du`), Telescope (`<leader>ff`, `<leader>fw`, `<A-x>`), NvimTree (`<leader>b`, `<leader>e`), and Windows (`<leader>x`, `<C-h/j/k/l>`).

### 7. [`07-cross-editor-unified-keybindings-architecture.md`](file:///home/addy/.config/nvim/documentation/07-cross-editor-unified-keybindings-architecture.md)
- **Cross-Editor Mnemonic Standard (Neovim, VSCode, Zed)**:
  - 2-stroke mnemonic hierarchy (`f`=find, `b`=sidebar/buffer, `c`=code/lsp, `s`=splits, `d`=debugger).
  - Complete master comparison table across Standalone Neovim, VSCode Neovim, and Zed Editor.
  - Ready-to-use JSON blueprints for VSCode `keybindings.json` and Zed `keymap.json`.
