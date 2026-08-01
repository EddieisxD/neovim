# 06 Master Keybindings Taxonomy & Cheat Sheet

This document is the unified master reference for all keybindings across Neovim Core, DAG Configuration Modules, Plugins, and VSCodium Adapter Mappings.

---

## ⌨️ 1. File Explorer (`NvimTree`)
| Keybind | Action | Description |
| :--- | :--- | :--- |
| **`<C-n>`** | `NvimTreeToggle` | Toggle NvimTree sidebar window |
| **`<leader>e`** | `NvimTreeFocus` | Focus cursor inside NvimTree |

---

## 🔍 2. Fuzzy Finder & Search (`Telescope`)
| Keybind | Action | Description |
| :--- | :--- | :--- |
| **`<leader>ff`** | `Telescope find_files` | Search files by name in CWD |
| **`<leader>fw`** | `Telescope live_grep` | Search text inside files (ripgrep) |
| **`<leader>fb`** | `Telescope buffers` | List active open buffers |
| **`<A-x>`** or **`<leader>c`** | `Telescope commands` | Doom Emacs style M-x command palette |
| **`<leader>fh`** | `Telescope help_tags` | Search Neovim help documentation |

---

## 🛠️ 3. Code Formatting (`conform.nvim`)
| Keybind / Command | Action | Description |
| :--- | :--- | :--- |
| **`<leader>fm`** | `Format` | Format current buffer asynchronously |
| **`:formatter format`** | `Formatter format` | Format current buffer |
| **`:formatter info`** | `Formatter info` | Display active `$PATH` formatters for current filetype |
| **`:formatter toggle`** | `Formatter toggle` | Toggle format-on-save |
| **`:formatter enable` / `disable`** | `Formatter enable` | Enable or disable auto-formatting |

---

## 🧹 4. Code Linting (`nvim-lint`)
| Command | Action | Description |
| :--- | :--- | :--- |
| **`:linter lint`** or **`:Lint`** | `Lint` | Trigger asynchronous linting on current buffer |
| **`:linter info`** | `Linter info` | Display active `$PATH` linters (`statix`, `shellcheck`, `luacheck`) |
| **`:linter toggle`** | `Linter toggle` | Toggle auto-linting on/off |

---

## 🧠 5. LSP Code Intelligence & Diagnostics
| Keybind / Command | Action | Description |
| :--- | :--- | :--- |
| **`K`** | `vim.lsp.buf.hover()` | Hover window (signatures, parameter docs for built-in & custom functions) |
| **`gd`** | `vim.lsp.buf.definition()` | Go to symbol definition |
| **`gD`** | `vim.lsp.buf.declaration()` | Go to symbol declaration |
| **`gr`** | `vim.lsp.buf.references()` | List all references to symbol |
| **`gi`** | `vim.lsp.buf.implementation()` | Go to interface implementation |
| **`<leader>ca`** | `vim.lsp.buf.code_action()` | Trigger LSP code actions / quickfixes |
| **`<leader>rn`** | `vim.lsp.buf.rename()` | Rename symbol across workspace |
| **`gl`** or **`<leader>cd`** | `vim.diagnostic.open_float()` | Open rounded floating diagnostic with `[source]` tag |
| **`]d`** / **`[d`** | `goto_next` / `goto_prev` | Jump to next or previous diagnostic warning/error |
| **`:lsp info`** | `Lsp info` | List active LSP clients attached to buffer |
| **`:lsp restart`** | `Lsp restart` | Restart LSP language servers |

---

## 🐛 6. DAP Debugging (`nvim-dap` + `nvim-dap-ui`)
| Keybind / Command | Action | Description |
| :--- | :--- | :--- |
| **`<leader>db`** | `DapToggleBreakpoint` | Toggle breakpoint on current line (`󰏤`) |
| **`<leader>dc`** | `DapContinue` | Start or continue debugging session |
| **`<leader>du`** | `DapUIToggle` | Toggle visual debugger UI panels (variables, stacks, watches) |
| **`:dap info`** | `Dap info` | Display active DAP debug session status |

---

## 🪟 7. Window Navigation & Buffer Management
| Keybind | Action | Description |
| :--- | :--- | :--- |
| **`<leader>w`** | `write` | Save current file |
| **`<leader>q`** | `quit` | Close current window |
| **`<leader>x`** | `bdelete` | Close active buffer / tab cleanly |
| **`<C-h>`** / **`<C-j>`** / **`<C-k>`** / **`<C-l>`** | `C-w h/j/k/l` | Navigate left / down / up / right between window splits |
| **`<Esc>`** | `nohlsearch` | Dismiss floating windows (LSP Hover, Diagnostics) & clear search highlights |

---

## 🚀 8. Vim Core Motions, Folds, Marks & Gototext Reference

### Goto Line Numbers & Jump History
- `[line_number]G` / `:[line_number]<Enter>` / `[line_number]gg`: Jump directly to line number.
- `Ctrl+o` / `Ctrl+i`: Move backward / forward in jump history.
- `''`: Teleport back to previous cursor line.
- `` ` ``: Teleport back to previous cursor line and column.
- `:jumps`: Display complete jump history.

### Folds (`zf`, `za`, `zR`, `zM`)
- `za`: Toggle fold at cursor.
- `zo` / `zc`: Open / close fold at cursor.
- `zR` / `zM`: Open all folds / close all folds across document.

### Word & Line-Level Motions
- `w` / `W`: Jump forward to start of next word / WORD.
- `b` / `B`: Jump backward to start of previous word / WORD.
- `e` / `E`: Jump forward to end of next word / WORD.
- `0`: Absolute beginning of line.
- `^`: First non-blank character of line.
- `$`: End of line.

### Local Character Searches
- `f[char]` / `F[char]`: Find and jump forward / backward to `[char]`.
- `t[char]` / `T[char]`: Jump forward / backward until just before `[char]`.
- `;` / `,`: Repeat previous character search forward / backward.

### File Marks
- `m[letter]`: Set mark at current position (e.g. `ma`).
- `'[letter]`: Teleport to line of mark `a`.
- `` `[letter] ``: Teleport to exact column and line of mark `a`.
- `m[Uppercase]`: Global mark across files (e.g. `mA`).

### Text Objects & Bracket Navigation
- `%`: Jump between matching pairs `()`, `[]`, `{}`.
- `[{` / `]}`: Jump to opening / closing brace of current block.
- `[(` / `])`: Jump to opening / closing parenthesis of current block.
