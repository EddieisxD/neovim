# Neovim Configuration Roadmap & Progress Log

## 🏛️ System Philosophy & Core Architectural Principles

### 1. Functional DAG Execution Engine
- **Engine**: Kahn's topological sorting algorithm with phase priorities (`SETUP` $\rightarrow$ `OPTIONS` $\rightarrow$ `KEYMAPS` $\rightarrow$ `AUTOCMDS` $\rightarrow$ `LOADER` $\rightarrow$ `PLUGINS` $\rightarrow$ `POST`).
- **Safety**: Built-in circular dependency detection and microsecond timing logs (`:DagStatus`, `:DagLog`).

### 2. Decoupled 3-Tier Data Architecture
- **`Bundle.settings`**: Control plane preferences ingested from [`lua/settings.lua`](file:///home/addy/.config/nvim/lua/settings.lua).
- **`Bundle.defaults`**: Sealed default fallback options and color palettes.
- **`Bundle.state`**: Live runtime memory and NvChad-style persistent storage (`~/.local/state/nvim/bundle_state.json`).
- **Single Dependency Rule**: Modules do not import each other directly; they communicate exclusively through `Bundle.state` and `Bundle.defaults`.

### 3. Metatable Encapsulation & Table Sealing
- `strict_table` and `seal` metatable guards prevent silent global variable pollution and catch typo errors immediately.
- `unseal()` bridge allows `Lazy.nvim` / `lze` to safely mutate spec keys without breaking configuration immutability.

### 4. Pure Nix & Traditional Dual-Mode Loader Adapter
- Universal spec format supporting both `Lazy.nvim` and `lze` (Nix wrapper modules).
- Switchable via [`lua/settings.lua`](file:///home/addy/.config/nvim/lua/settings.lua) (`loader = "lazy"` or `loader = "lze"`).

### 5. Mason-Free Environment Sourcing Engine
- Automatically scans `$PATH` (`direnv`, `nix-shell`, `nix develop`, system binaries) for active LSPs, Formatters, and Linters.
- Zero reliance on Mason for NixOS environments, while retaining optional Mason support for non-Nix environments.

### 6. NvChad-Style Cross-Session Persistent State Engine
- Persists user runtime choices (`colorscheme`, `transparent`, `number`, `relativenumber`) in `~/.local/state/nvim/bundle_state.json`.
- Survives NixOS rebuilds without needing code modifications or flake rebuilds for UI preference changes.

---

## 📌 Implementation Checklist & Active Tasks

- [x] **Step 1: Git Tag `v2`**: Baseline DAG architecture tagged (`4301401`).
- [x] **Phase 1: Universal Treesitter & Textobjects**:
  - `wrapper_modules` dual-mode `FileType` auto-attach engine.
  - `nvim-treesitter.withAllGrammars` collated Nix grammars + textobjects keymaps (`af`, `if`, `ac`, `ic`, `aa`, `ia`).
  - Executable compiler check (`tree-sitter-cli`) preventing `ENOENT` crashes (`59231ce`).
- [/] **Phase 2: Modern `NotAShelf/direnv.nvim` Environment Auto-Sourcing**:
  - Replaced legacy `direnv.vim` with modern **`NotAShelf/direnv.nvim`** (pure Lua direnv integration by creator of `nvf`).
  - Eliminates terminal ANSI control code leakage (`^[[0mdirenv: unloading`).
  - Integrated with `fidget.nvim` non-blocking progress handles.
- [ ] **Phase 3: Floating LSP Diagnostics Keymap & Formatting Separation**:
  - Added LSP floating diagnostic window keymap (`<leader>cd` / `gl` $\rightarrow$ `vim.diagnostic.open_float()`).
  - Detached auto format-on-save (`M.format_on_save = false`), keeping save and format as separate explicit actions (`<leader>fm` for manual formatting).
  - Added feature flags & toggle commands (`:ToggleFormatter`, `:ToggleLinter`, `:ToggleDAP`).
- [ ] **Phase 4: `conform.nvim` Formatter Engine**:
  - Modular formatting engine reading `$PATH` binaries with manual formatting keymap `<leader>fm`.
- [ ] **Phase 5: `nvim-lint` Linter Engine**:
  - Modular linting engine reading `$PATH` linters with toggle flag.
- [ ] **Phase 6: `nvim-dap` + `nvim-dap-ui` Debugger Engine**:
  - Full DAP debugging client with visual UI panels (`<leader>db`, `<leader>dc`, `<leader>du`) and toggle flag.
