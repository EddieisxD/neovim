# Master Keybindings Reference & Cheat Sheet

For the complete, categorized keybindings taxonomy and architectural documentation, see [`06-master-keybindings-guide.md`](file:///home/addy/.config/nvim/documentation/06-master-keybindings-guide.md).

---

## ⌨️ Quick Reference Overview

### 1. File Explorer & Search
- **`<C-n>`**: Toggle NvimTree file explorer
- **`<leader>e`**: Focus NvimTree file explorer
- **`-`**: Open parent directory in Oil editable buffer file explorer
- **`<leader>ff`**: Find files by name (Telescope)
- **`<leader>fw`**: Search text in workspace via ripgrep (Telescope)
- **`<leader>fb`**: Find open buffers (Telescope)
- **`<A-x>`** / **`<leader>c`**: Command palette (Doom Emacs style M-x)

### 2. Code Intelligence & LSP
- **`K`**: LSP Hover documentation & function signatures (for built-in and custom functions)
- **`gd`**: Go to definition / Open `[[wikilink]]` note (creates buffer if missing)
- **`<C-w>gd`**: Open definition / `[[wikilink]]` note in a **new vertical split**
- **`gD`**: Go to declaration
- **`gr`**: Go to references / PKM vault backlinks
- **`gi`**: Go to implementation
- **`<leader>ca`**: LSP code actions / quickfixes / Add word to dictionary / Create missing note
- **`<leader>rn`**: Rename symbol across workspace / PKM vault
- **`gl`** / **`<leader>cd`**: Open rounded floating diagnostic with `[source]` tag
- **`]d`** / **`[d`**: Jump to next / previous diagnostic

### 3. PKM Note-Taking & Dictionary Management
- **`:Daily`**: Open/create daily note (`:Daily`, `:Daily tomorrow`, `:Daily -1`)
- **`<leader>mc`** / **`<leader>tc`**: Cycle checkbox `[ ]` $\rightarrow$ `[/]` $\rightarrow$ `[x]`
- **`<leader>mp`** / **`<leader>pi`**: Paste image from clipboard to `./assets/` and insert link
- **`zg`**: Add word under cursor to portable `dictionary.utf-8.add`
- **`zw`**: Mark word under cursor as misspelled
- **`zug`**: Undo adding word to dictionary

### 4. Formatting, Linting & DAP Debugging
- **`<leader>fm`**: Format current buffer asynchronously (`conform.nvim`)
- **`:linter lint`**: Trigger linting asynchronously (`nvim-lint`)
- **`<leader>db`**: Toggle DAP breakpoint (`󰏤`)
- **`<leader>dc`**: Start or continue DAP debugging session
- **`<leader>du`**: Toggle visual DAP UI panels

### 5. Window Splits, Tabpages & Buffer Navigation
- **`]b`**: Switch to next open buffer
- **`[b`**: Switch to previous open buffer
- **`<leader>sv`**: Split window vertically (`:vsplit`)
- **`<leader>sh`**: Split window horizontally (`:split`)
- **`<leader>se`**: Make all window splits equal size (`<C-w>=`)
- **`<leader>sx`**: Close current window split (`:close`)
- **`<leader>st`**: Move current split into a new tab page (`:tab split`)
- **`<leader>sm`**: Move tab buffer back into a vertical split
- **`gt`** / **`gT`**: Jump to next / previous tab page
- **`<leader>w`**: Save file
- **`<leader>q`**: Quit window
- **`<leader>x`**: Close active buffer / tab
- **`<C-h/j/k/l>`**: Focus left / down / up / right window split
- **`<Esc>`**: Dismiss floating windows (LSP Hover, Diagnostics) & clear search highlights
