# Neovim Configuration Roadmap & Progress Log

## 🏛️ System Philosophy & Core Architectural Principles

### 1. Functional DAG Execution Engine
- **Engine**: Kahn's topological sorting algorithm with phase priorities (`SETUP` $\rightarrow$ `OPTIONS` $\rightarrow$ `KEYMAPS` $\rightarrow$ `AUTOCMDS` $\rightarrow$ `LOADER` $\rightarrow$ `PLUGINS` $\rightarrow$ `POST`).
- **Safety**: Built-in circular dependency detection and microsecond timing logs (`:DagStatus`, `:DagLog`).

### 2. Decoupled 3-Tier Data Architecture & Isolation Modes
- **`Bundle.settings`**: Control plane preferences ingested from [`lua/settings.lua`](file:///home/addy/.config/nvim/lua/settings.lua).
- **`Bundle.defaults`**: Sealed immutable fallback tables.
- **`Bundle.state`**: Live runtime memory and persistent state engine.
- **Isolation Modes (`isolation` setting)**:
  - **`strict`**: Zero disk persistence. Ignores `bundle_state.json`, reads directly from `Bundle.defaults`. Undo files live impermanently in `/tmp/neovim/undo`.
  - **`tmp`**: Impermanent state persistence. `bundle_state.json` and undo files stored in `/tmp/neovim/`.
  - **`flexible` (Default)**: Permanent state persistence. `bundle_state.json` stored in `~/.local/state/nvim/bundle_state.json` and undo files stored in `~/.local/state/nvim/undo`.

### 3. Metatable Encapsulation & Table Sealing
- `strict_table` and `seal` metatable guards prevent silent global variable pollution and catch typo errors immediately.
- `unseal()` bridge allows `Lazy.nvim` / `lze` to safely mutate spec keys without breaking configuration immutability.

### 4. Pure Nix & Traditional Dual-Mode Loader Adapter
- Universal spec format supporting both `Lazy.nvim` and `lze` (Nix wrapper modules).
- Switchable via [`lua/settings.lua`](file:///home/addy/.config/nvim/lua/settings.lua) (`loader = "lazy"` or `loader = "lze"`).

### 5. Mason-Free Environment Sourcing Engine
- Automatically scans `$PATH` (`direnv`, `nix-shell`, `nix develop`, system binaries) for active LSPs, Formatters, Linters, and Debuggers.
- Zero reliance on Mason for NixOS environments, while retaining optional Mason support for non-Nix environments.

---

## 📌 v3 Implementation Checklist & Active Roadmap

- [x] **Step 1: Git Tag `v2`**: Baseline DAG architecture tagged (`4301401`).
- [x] **Phase 1: Universal Treesitter & Textobjects**:
  - `wrapper_modules` dual-mode `FileType` auto-attach engine with `nvim-treesitter.withAllGrammars`.
  - Smart textobjects keymaps (`af`, `if`, `ac`, `ic`, `aa`, `ia`) and `tree-sitter-cli` guard (`59231ce`).
- [x] **Phase 2: Modern `NotAShelf/direnv.nvim` Environment Auto-Sourcing**:
  - Replaced legacy `direnv.vim` with pure Lua `NotAShelf/direnv.nvim`.
  - Non-blocking asynchronous direnv evaluation with Fidget progress spinner animations and interactive `:direnv` commands.
- [x] **Phase 3: Fidget Notifications & Decoupled `notify_handler` Subscriber**:
  - Decoupled `Bundle:notify` engine with `:messages` error mirroring and Fidget progress handles.
- [x] **Phase 4: 3-Tier Isolation Modes & Permanent Undo Directory**:
  - Support for `strict`, `tmp`, and `flexible` isolation modes with `/tmp/neovim/` fallback directories.
- [x] **Phase 5: Unified `:lsp` Command Suite & Cabbrev Aliases**:
  - Dynamic `$PATH` LSP server scanner (`nil_ls`, `nixd`, `lua_ls`, `pyright`, `gopls`, `rust_analyzer`, `clangd`).
  - Unified `:lsp` command suite (`enable`, `disable`, `restart`, `stop`, `start`, `info`) with tab completion.
- [x] **Phase 6: `conform.nvim` Formatter Engine**:
  - Asynchronous code formatting sourced dynamically from `$PATH` (`stylua`, `nixfmt`, `shfmt`, `black`, `rustfmt`, `gofmt`, `prettier`, `clang-format`).
  - Keymap `<leader>fm` and unified `:formatter` command suite (`enable`, `disable`, `toggle`, `format`, `info`).
- [x] **Phase 7: `nvim-lint` Linter Engine**:
  - Asynchronous code linting engine with `$PATH` discovery (`statix`, `shellcheck`, `luacheck`, `flake8`, `eslint`).
  - Unified `:linter` command suite (`enable`, `disable`, `toggle`, `lint`, `info`).
- [x] **Phase 8: `nvim-dap` + `nvim-dap-ui` Debugger Engine**:
  - Full DAP debugging client with visual UI panels (`<leader>db`, `<leader>dc`, `<leader>du`).
  - Unified `:dap` command suite (`enable`, `disable`, `toggle`, `start`, `toggle_breakpoint`, `ui_toggle`, `info`).

---

## 📋 TODO & Deep Verification Backlog

- [ ] **Deep Testing: `nvim-dap` Debugger Adapters**:
  - Comprehensive testing of DAP debugger attachment (`codelldb`, `python`, `gdb`, `go`).
  - Verify breakpoint persistence, UI panel layout responsiveness, and in-line virtual text rendering.
- [ ] **Deep Testing: `nvim-lint` Linter Attachment**:
  - Validate async diagnostic mapping for `statix`, `shellcheck`, `luacheck`, `flake8`, and `eslint`.
  - Ensure zero interference between LSP diagnostics and linter diagnostic namespaces.
- [ ] **LSP Environment Engine Edge Sharpening & Refinements**:
  - Refine auto-attach handlers for multi-root workspace projects.
  - Audit server command table definitions and suppress extraneous RPC stderr warnings.
- [ ] **Borderless NvimTree Separator Refinement**:
  - Re-evaluate window split highlight group overrides for NvimTree borderless styling across third-party colorschemes.
- [ ] **Post-v3 Deep Code Review & Performance Optimization Sprint**:
  - Comprehensive code review of every module to benchmark execution speed, eliminate redundant hooks, and ensure 100% DAG crash resilience.
