# Master Keybindings Reference & Cheat Sheet

For the complete, categorized keybindings taxonomy and architectural documentation, see [`06-master-keybindings-guide.md`](file:///home/addy/.config/nvim/documentation/06-master-keybindings-guide.md).

---

## ⌨️ Quick Reference Overview

### 1. File Explorer & Search
- **`<C-n>`**: Toggle NvimTree file explorer
- **`<leader>e`**: Focus NvimTree file explorer
- **`<leader>ff`**: Find files by name (Telescope)
- **`<leader>fw`**: Search text in workspace via ripgrep (Telescope)
- **`<leader>fb`**: Find open buffers (Telescope)
- **`<A-x>`** / **`<leader>c`**: Command palette (Doom Emacs style M-x)

### 2. Code Intelligence & LSP
- **`K`**: LSP Hover documentation & function signatures (for built-in and custom functions)
- **`gd`**: Go to definition
- **`gD`**: Go to declaration
- **`gr`**: Go to references
- **`gi`**: Go to implementation
- **`<leader>ca`**: LSP code actions / quickfixes
- **`<leader>rn`**: Rename symbol across workspace
- **`gl`** / **`<leader>cd`**: Open rounded floating diagnostic with `[source]` tag
- **`]d`** / **`[d`**: Jump to next / previous diagnostic

### 3. Formatting, Linting & DAP Debugging
- **`<leader>fm`**: Format current buffer asynchronously (`conform.nvim`)
- **`:linter lint`**: Trigger linting asynchronously (`nvim-lint`)
- **`<leader>db`**: Toggle DAP breakpoint (`󰏤`)
- **`<leader>dc`**: Start or continue DAP debugging session
- **`<leader>du`**: Toggle visual DAP UI panels

### 4. Window & Buffer Controls
- **`<leader>w`**: Save file
- **`<leader>q`**: Quit window
- **`<leader>x`**: Close active buffer / tab
- **`<C-h/j/k/l>`**: Focus left / down / up / right window split
- **`<Esc>`**: Dismiss floating windows (LSP Hover, Diagnostics) & clear search highlights
