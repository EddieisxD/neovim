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
  - Eliminates terminal ANSI control code leakage (`^[[0mdirenv: unloading`).
- [ ] **Phase 3: Fidget Notifications for `direnv`**:
  - Route all direnv exports and load events through `fidget.notify` so the user is always notified when a Nix shell is ingested.
- [ ] **Phase 4: 3-Tier Isolation Modes (`strict` | `tmp` | `flexible`) & Permanent Undo Directory**:
  - Configure `isolation` setting in `lua/settings.lua` and `lua/meta.lua`.
  - Move `undodir` in [`lua/modules/options.lua`](file:///home/addy/.config/nvim/lua/modules/options.lua) to `~/.local/state/nvim/undo` for `flexible` mode, and `/tmp/neovim/undo` for `strict`/`tmp` modes.
- [ ] **Phase 5: Auto-Attach Toggles & `:Lsp` Command Suite**:
  - Enable `auto_attach_lsp = true`, `auto_attach_formatter = true`, `auto_attach_linter = true`, `auto_attach_dap = true` in `lua/settings.lua`.
  - Provide `:Lsp` command suite with autocompletion (`:Lsp enable <name>`, `:Lsp disable <name>`, `:Lsp restart <name>`, `:Lsp stop <name>`, `:Lsp info`).
- [ ] **Phase 6: `conform.nvim` Formatter Engine**:
  - Modular formatting engine reading `$PATH` binaries with manual formatting keymap `<leader>fm`. Format on save detached by default (`M.format_on_save = false`).
- [ ] **Phase 7: `nvim-lint` Linter Engine**:
  - Modular linting engine reading `$PATH` linters with toggle flag.
- [ ] **Phase 8: `nvim-dap` + `nvim-dap-ui` Debugger Engine**:
  - Full DAP debugging client with visual UI panels (`<leader>db`, `<leader>dc`, `<leader>du`).
- [ ] **Phase 9: Post-v3 Deep Code Review & Performance Optimization Sprint**:
  - Comprehensive code review of every module to benchmark execution speed, eliminate redundant hooks, and ensure 100% DAG crash resilience.
