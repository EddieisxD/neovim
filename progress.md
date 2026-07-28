# Neovim Configuration Roadmap & Progress Log

## 🚀 Accomplished Architecture & Core Features

### 1. Functional DAG Execution Engine
- **Engine**: Kahn's topological sorting algorithm with phase priorities (`SETUP` $\rightarrow$ `OPTIONS` $\rightarrow$ `KEYMAPS` $\rightarrow$ `AUTOCMDS` $\rightarrow$ `LOADER` $\rightarrow$ `PLUGINS` $\rightarrow$ `POST`).
- **Safety**: Built-in circular dependency detection and step timing logs (`:DagStatus`, `:DagLog`).

### 2. Metatable Encapsulation & Table Sealing
- `strict_table` and `seal` metatable guards prevent silent global variable pollution and catch typo errors immediately.
- `unseal()` bridge allows `Lazy.nvim` / `lze` to safely mutate spec keys without breaking configuration immutability.

### 3. Pure Nix & Traditional Dual-Mode Loader Adapter
- Universal spec format supporting both `Lazy.nvim` and `lze` (Nix wrapper modules).
- Switchable via [`lua/settings.lua`](file:///home/addy/.config/nvim.wip/lua/settings.lua) (`loader = "lazy"` or `loader = "lze"`).

### 4. Mason-Free Environment Sourcing Engine
- Automatically scans `$PATH` (`direnv`, `nix-shell`, `nix develop`, system binaries) for active LSPs, Formatters, and Linters.
- Zero reliance on Mason for NixOS environments, while retaining optional Mason support for non-Nix environments.

### 5. NvChad-Style Cross-Session Persistent State Engine
- Persists user runtime choices (`colorscheme`, `transparent`, `number`, `relativenumber`) in `~/.local/state/nvim/bundle_state.json`.
- Survives NixOS rebuilds without needing code modifications or flake rebuilds for UI preference changes.

### 6. Decoupled `Bundle.state` & `Bundle.defaults` Architecture
- **Single Dependency Rule**: Modules do not import each other. Modules publish live state to `Bundle.state` and read fallbacks from `Bundle.defaults`.
- **Swappability**: Replacing any module file requires zero code changes in other modules.

### 7. Core UI & Developer Workflows
- **Telescope**: Customized layout (Bottom prompt bar with 30% Fuzzy Results / 70% Preview split) + `live_grep` ripgrep integration.
- **Blink.cmp**: Super-tab preset completion unblocking Insert-mode `<Tab>` indentation + self-healing native build step for Blink V2.
- **Lualine**: Dynamic statusbar displaying active LSPs, Formatters, and Linters.
- **Fidget.nvim**: Smooth, unthrottled LSP progress and notification UI.
- **All-or-Nothing Transparency Engine**: `:ToggleTransparency` and `:ApplyTransparency` commands that automatically re-apply over colorschemes while respecting persistent state.
- **Kitty Terminal Integration**: Automatic window padding removal on `UIEnter` / `VimEnter` via Kitty remote control (`kitty @ set-spacing padding=0`).
- **Clean Gutter**: Removed end-of-buffer `~` tildes via `fillchars`.
- **Curated Theme Collection**: Catppuccin, Oxocarbon, Carbonfox (Nightfox), Kanagawa, Gruvbox-Material, Vague, and Oldworld.

---

## 🎯 Future Feature Backlog & Roadmap

The following items are planned for future integration into our modular DAG system:

- [ ] **Dynamic Colorscheme Lazy-Loading Optimization**: Evaluate dynamic lazy-loading of non-active themes vs eager loading all colorschemes at boot.
- [ ] **Nix-backed `lazy.nvim` Hybrid Mode**: Support passing Nix store plugin paths directly into `lazy.nvim` (via `dir = "/nix/store/..."` or Nix wrappers) so `lazy.nvim` UI can be used even when plugins are supplied by Nix flakes.
- [ ] **Dynamic `render-markdown.nvim` Palette per Colorscheme**: Automatically adjust Markdown heading and code block highlight colors based on the active colorscheme in `Bundle.state.colorscheme`.
- [ ] **Bufferline / Tabline**: Modern tab/buffer bar integration.
- [ ] **`nvim-persistence`**: Session management to save and restore open buffers, layouts, and cursor positions.
- [ ] **LSP Mux / Multi-server Routing**: Advanced multiplexing and fallback routing for concurrent LSPs.
- [ ] **VSCode Headless Mode**: Detect `vim.g.vscode` and suppress heavy UI/syntax plugins when running embedded inside VSCode.
- [ ] **DAP (Debug Adapter Protocol)**: Full debugging capability (`nvim-dap`, `nvim-dap-ui`).
- [ ] **AI Integration**: Copilot / Codeium / Avante.nvim for AI-assisted editing.
- [ ] **Obsidian.nvim / Logseq.nvim**: PKM (Personal Knowledge Management) note-taking workflows.
- [ ] **Org Mode + Extensions**: Emacs-style Org-mode editing in Neovim.
- [ ] **Neorg**: Modern structured note-taking ecosystem.
- [ ] **`image.nvim`**: In-buffer image rendering (Kitty / Überzug graphics protocol).
- [ ] **`latex.nvim` / VimTeX**: LaTeX compilation, forward/backward search, and previewing.
- [ ] **`direnv` Integration**: Automatic environment variable reloading (`direnv.vim` / `env-runner`).
- [ ] **Container Support & Devcontainers**: Remote container editing and LSP attached inside Docker/Podman devcontainers.
- [ ] **SSH Support**: Remote file editing and remote LSP session attachment over SSH.
- [ ] **Markdown Oxide Integration**: PKM language server for Markdown wikilinks, tags, and back-links.
- [ ] **Heirline (Optional Statusline)**: Fully customizable, lightweight statusline alternative.
- [ ] **`mermaid.nvim`**: Diagram and flowchart previewing for Markdown.
- [ ] **Yazi Integration**: Terminal file manager integration inside Neovim split/float.
- [ ] **`gitsigns.nvim`**: Inline git diff signs, hunk preview, and line blame.
- [ ] **`neogit`**: Full Magit-like Git interface for Neovim.
- [ ] **`noice.nvim`**: Fancy UI for messages, cmdline, and popupmenu.
- [ ] **Neovide GUI Integration**: Native GUI optimizations when running under Neovide.
- [ ] **`harper.nvim`**: Grammar and spell checking LSP for documentation & prose.
