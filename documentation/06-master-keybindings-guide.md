# 06 Master Keybindings Taxonomy & Cheat Sheet

This document is the unified master reference for all keybindings across Neovim Core, DAG Configuration Modules, Plugins, and VSCodium Adapter Mappings.

---

## ⌨️ 1. File Explorer (`NvimTree` & `Oil.nvim`)
| Keybind | Action | Description |
| :--- | :--- | :--- |
| **`<C-n>`** | `NvimTreeToggle` | Toggle NvimTree sidebar window |
| **`<leader>e`** | `NvimTreeFocus` | Focus cursor inside NvimTree |
| **`-`** | `Oil` | Open parent directory in Oil editable buffer file explorer |

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
| **`gd`** | `vim.lsp.buf.definition()` | Go to symbol definition / Open `[[wikilink]]` note (creates file if missing) |
| **`<C-w>gd`** | `split_definition` | Open symbol definition / `[[wikilink]]` note in a **new vertical split** |
| **`gD`** | `vim.lsp.buf.declaration()` | Go to symbol declaration |
| **`gr`** | `vim.lsp.buf.references()` | List all references to symbol / vault backlinks |
| **`gi`** | `vim.lsp.buf.implementation()` | Go to interface implementation |
| **`<leader>ca`** | `vim.lsp.buf.code_action()` | Trigger LSP code actions / quickfixes / Add word to dictionary / Create missing note |
| **`<leader>rn`** | `vim.lsp.buf.rename()` | Rename symbol across workspace / PKM vault |
| **`gl`** or **`<leader>cd`** | `vim.diagnostic.open_float()` | Open rounded floating diagnostic with `[source]` tag |
| **`]d`** / **`[d`** | `goto_next` / `goto_prev` | Jump to next or previous diagnostic warning/error |
| **`:lsp info`** | `Lsp info` | List active LSP clients attached to buffer |
| **`:lsp restart`** | `Lsp restart` | Restart LSP language servers |

---

## 📝 6. PKM Note-Taking & Dictionary Management (`markdown-oxide` & `harper_ls`)
| Keybind / Command | Action | Description |
| :--- | :--- | :--- |
| **`:Daily`** | `Daily [args]` | Open/create daily note (`:Daily`, `:Daily tomorrow`, `:Daily -1`) |
| **`<leader>mc`** or **`<leader>tc`** | `toggle_checkbox` | Cycle Markdown checkbox `[ ]` $\rightarrow$ `[/]` $\rightarrow$ `[x]` |
| **`<leader>mp`** or **`<leader>pi`** | `paste_image` | Paste image from clipboard to `./assets/` and insert link |
| **`zg`** | `spell_add` | Add word under cursor to portable `dictionary.utf-8.add` |
| **`zw`** | `spell_bad` | Mark word under cursor as misspelled |
| **`zug`** | `spell_undo` | Undo adding word to dictionary |

---

## 🐛 7. DAP Debugging (`nvim-dap` + `nvim-dap-ui`)
| Keybind / Command | Action | Description |
| :--- | :--- | :--- |
| **`<leader>db`** | `DapToggleBreakpoint` | Toggle breakpoint on current line (`󰏤`) |
| **`<leader>dc`** | `DapContinue` | Start or continue debugging session |
| **`<leader>du`** | `DapUIToggle` | Toggle visual debugger UI panels (variables, stacks, watches) |
| **`:dap info`** | `Dap info` | Display active DAP debug session status |

---

## 🪟 8. Window Splits, Tabpages & Buffer Navigation
| Keybind | Action | Description |
| :--- | :--- | :--- |
| **`]b`** | `bnext` | Switch to next open buffer |
| **`[b`** | `bprevious` | Switch to previous open buffer |
| **`<leader>sv`** | `vsplit` | Split window vertically |
| **`<leader>sh`** | `split` | Split window horizontally |
| **`<leader>se`** | `<C-w>=` | Make all window splits equal size |
| **`<leader>sx`** | `close` | Close current window split |
| **`<leader>st`** | `wincmd T` | **Move current split into a new tab page** |
| **`<leader>sm`** | `tab_to_split` | **Move tab buffer back into a vertical split** |
| **`gt`** / **`gT`** | `tabnext` / `tabprev` | Jump to next / previous tab page |
| **`<leader>w`** | `write` | Save current file |
| **`<leader>q`** | `quit` | Close current window |
| **`<leader>x`** | `bdelete` | Close active buffer / tab cleanly |
| **`<C-h>`** / **`<C-j>`** / **`<C-k>`** / **`<C-l>`** | `C-w h/j/k/l` | Navigate left / down / up / right between window splits |
| **`<Esc>`** | `nohlsearch` | Dismiss floating windows (LSP Hover, Diagnostics) & clear search highlights |
