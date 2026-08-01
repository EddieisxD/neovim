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
- [x] **Phase 1: Universal Treesitter & Textobjects**: Dual-mode `FileType` auto-attach with `tree-sitter-cli` guard (`59231ce`).
- [x] **Phase 2: Modern `NotAShelf/direnv.nvim` Environment Auto-Sourcing**: Non-blocking direnv evaluation with Fidget progress spinner.
- [x] **Phase 3: Fidget Notifications & Decoupled `notify_handler` Subscriber**: Decoupled `Bundle:notify` engine.
- [x] **Phase 4: 3-Tier Isolation Modes & Permanent Undo Directory**: `strict`, `tmp`, and `flexible` isolation modes.
- [x] **Phase 5: Unified `:lsp` Command Suite & Cabbrev Aliases**: Dynamic `$PATH` LSP server scanner & `:lsp` suite.
- [x] **Phase 6: `conform.nvim` Formatter Engine**: Asynchronous `$PATH` code formatting engine with `<leader>fm` & `:formatter`.
- [x] **Phase 7: `nvim-lint` Linter Engine**: Asynchronous `$PATH` linting engine with `:linter`.
- [x] **Phase 8: `nvim-dap` + `nvim-dap-ui` Debugger Engine**: Full DAP debugger client (`<leader>db`, `<leader>dc`, `<leader>du`) and `:dap`.
- [x] **Phase 9: Neovide & VSCode/VSCodium GUI Integration**: Glassmorphism, padding, and Centralized Keymap Registry (`keymap_registry.bind`).
- [x] **Phase 10: Kitty Remote Terminal Padding Synchronization**: Asynchronous Kitty remote padding & margin synchronization.

---

## 📋 Pre-v3 Finalization Agenda & Priority Execution Backlog

- [ ] **Task 1: Obsidian / Markdown-Oxide PKM Note-Taking Integration**:
  - Configure `markdown-oxide` LSP server with PKM keybindings for daily notes, backlinks, and tags.
  - Evaluate `obsidian.nvim` / `orgmode` fallback options if unsatisfied with plain markdown-oxide.
- [ ] **Task 2: Harper Grammar Engine, Custom Portable Dictionary & Snippets**:
  - Integrate `harper_ls` for grammar, spellchecking, and typo detection across Markdown PKM notes and code.
  - Setup custom portable dictionary (`~/.config/nvim/dictionary.utf-8.add`) tracked in config.
  - Enable Harper completions and custom snippet management (`luasnip` / `blink-cmp`).
- [ ] **Task 3: Window Split Management Suite**:
  - Add explicit window split keybindings (`<leader>sv` split vertical, `<leader>sh` split horizontal, `<leader>se` equal splits, `<leader>sx` close split).
  - Ensure side-by-side code comparison layout works seamlessly with `<C-h/j/k/l>` navigation.
- [ ] **Task 4: Bufferline & Visual Buffer Management System**:
  - Integrate visual buffer tabbar (e.g. `akinsho/bufferline.nvim` or `barbar.nvim`) or quick buffer navigation (`<S-h>` previous buffer, `<S-l>` next buffer, `<leader>bp` buffer pick).
  - Eliminate requirement of reopening hidden buffers from NvimTree.
- [ ] **Task 5: Direnv CWD Sync Bug Audit**:
  - Deeply audit `NotAShelf/direnv.nvim` & `:cd` autocmds to eliminate intermittent directory sync dropouts.
- [ ] **Task 6: File Explorer Upgrade / Evaluation**:
  - Benchmark `oil.nvim` (editable buffer file explorer) or `neo-tree` / `mini.files` as potential replacements if `nvim-tree` feels "off".
- [ ] **Task 7: UI Polish & Transparency Uniformity**:
  - Fix Kanagawa and third-party colorscheme Fidget background highlights (`FidgetTitle`, `FidgetTask`, `FidgetNormal`).
  - Refine Lualine attached tooling indicator (only display active attached LSPs/Formatters/Linters using curated Nerd Font glyphs).
  - Fix Neovide solid black lines rendering artifact.
- [ ] **Task 8: Colorscheme De-bloating & Unused Plugin Cleanup**:
  - Remove unused colorschemes (`oxocarbon`, `nightfox`, `kanagawa`, `gruvbox-material`, `vague-nvim`), retaining Catppuccin Mocha as sole curated theme.
  - Remove unused Mason plugins (`mason.lua`, `mason-nvim`, `mason-lspconfig-nvim`) to eliminate command pollution (`:Mason`) and optimize boot time.
- [ ] **Task 9: Deep Code Review & v3 Tagging**:
  - Comprehensive codebase audit, execution speed benchmarking (`:DagLog`), and `v3` git tagging.
