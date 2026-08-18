# 07 Cross-Editor Unified Keybindings Architecture (Neovim, VSCode, Zed)

This document establishes the **Universal Mnemonic Keybinding System** designed to maintain **100% muscle-memory consistency** across **Standalone Neovim (TUI & Neovide)**, **VSCode (vscode-neovim)**, and **Zed Editor (Vim Mode)**.

---

## 1. Architectural Philosophy: The Mnemonic 2-Stroke System

Rather than remembering ad-hoc shortcuts across three different editors, every action is organized under `<Leader>` (`<Space>`) followed by a single mnemonic domain letter:

```
<Leader> (<Space>)
 ├── b ────── Sidebar / Left Dock Toggle & Buffer Management
 ├── e ────── Explorer / File Tree Focus Toggle
 ├── f ────── Find & Fuzzy Pickers (Files, Grep, Buffers, Recent, Symbols)
 ├── c ────── Code Intelligence & LSP (Actions, Rename, Format, Diagnostics)
 ├── s ────── Window Splits & Layouts (Vert, Horiz, Close, Equal)
 ├── d ────── Debugger & DAP (Toggle BP, Continue, UI)
 ├── g ────── Git Operations (Status, Diff, Blame)
 └── t ────── Toggles (Terminal, Diagnostics, Line Numbers, Transparency)
```

---

## 2. Universal Master Matrix Across All Editors

### 📁 1. File Explorer & Sidebars
| Action | Keybinding | Neovim TUI / Neovide | VSCode (`vscode-neovim`) | Zed Editor (`keymap.json`) |
| :--- | :--- | :--- | :--- | :--- |
| **Toggle Sidebar** | `<leader>b` | `NvimTreeToggle` | `workbench.action.toggleSidebarVisibility` | `workspace::ToggleLeftDock` |
| **Toggle Explorer Focus** | `<leader>e` | `NvimTreeFocus` / `wincmd p` | `workbench.files.action.focusFilesExplorer` | `project_panel::ToggleFocus` |
| **Parent Dir Editor** | `-` | `Oil` | *(N/A)* | *(N/A)* |

---

### 🔍 2. Finding & Fuzzy Pickers (`<leader>f...`)
| Action | Keybinding | Neovim (Telescope) | VSCode | Zed Editor |
| :--- | :--- | :--- | :--- | :--- |
| **Find Files** | `<leader>ff` | `Telescope find_files` | `workbench.action.quickOpen` | `file_finder::Toggle` |
| **Live Grep / Search** | `<leader>fw` | `Telescope live_grep` | `workbench.action.findInFiles` | `workspace::NewSearch` |
| **Find Open Buffers** | `<leader>fb` | `Telescope buffers` | `workbench.action.showAllEditors` | `tab_switcher::Toggle` |
| **Recent Files** | `<leader>fr` | `Telescope oldfiles` | `workbench.action.openRecent` | `file_finder::ToggleFilters` |
| **Symbol Search** | `<leader>fs` | `Telescope lsp_document_symbols` | `workbench.action.gotoSymbol` | `project_symbols::Toggle` |
| **Command Palette** | `<leader>c` / `<A-x>` | `Telescope commands` | `workbench.action.showCommands` | `command_palette::Toggle` |

---

### 📑 3. Buffer & File Operations
| Action | Keybinding | Neovim | VSCode | Zed Editor |
| :--- | :--- | :--- | :--- | :--- |
| **Close Buffer / Tab** | `<leader>x` | `:bdelete` | `workbench.action.closeActiveEditor` | `pane::CloseActiveItem` |
| **Next Buffer** | `]b` | `:bnext` | `workbench.action.nextEditor` | `pane::ActivateNextItem` |
| **Previous Buffer** | `[b` | `:bprevious` | `workbench.action.previousEditor` | `pane::ActivatePrevItem` |
| **Save File** | `<leader>w` | `:w` | `workbench.action.files.save` | `workspace::Save` |
| **Quit / Close Window** | `<leader>q` | `:q` | `workbench.action.closeActiveEditor` | `pane::CloseActiveItem` |

---

### 🧠 4. Code Intelligence & Language Server (`<leader>c...` & `g...`)
| Action | Keybinding | Neovim (LSP) | VSCode | Zed Editor |
| :--- | :--- | :--- | :--- | :--- |
| **Go to Definition** | `gd` | `vim.lsp.buf.definition` | `editor.action.revealDefinition` | `editor::GoToDefinition` |
| **Go to Declaration** | `gD` | `vim.lsp.buf.declaration` | `editor.action.revealDeclaration` | `editor::GoToDeclaration` |
| **Go to Implementation**| `gi` | `vim.lsp.buf.implementation` | `editor.action.goToImplementation` | `editor::GoToImplementation` |
| **Go to References** | `gr` | `vim.lsp.buf.references` | `editor.action.goToReferences` | `editor::FindAllReferences` |
| **Hover Documentation** | `K` | `vim.lsp.buf.hover` | `editor.action.showHover` | `editor::Hover` |
| **Format Document** | `<leader>fm` | `conform.format` | `editor.action.formatDocument` | `editor::Format` |
| **Code Actions / Fix** | `<leader>ca` | `vim.lsp.buf.code_action` | `editor.action.quickFix` | `editor::ToggleCodeActions` |
| **Rename Symbol** | `<leader>rn` | `vim.lsp.buf.rename` | `editor.action.rename` | `editor::Rename` |
| **Next Diagnostic** | `]d` | `vim.diagnostic.goto_next` | `editor.action.marker.next` | `editor::GoToDiagnostic` |
| **Prev Diagnostic** | `[d` | `vim.diagnostic.goto_prev` | `editor.action.marker.prev` | `editor::GoToPrevDiagnostic` |
| **Floating Diagnostic** | `<leader>cd` | `vim.diagnostic.open_float` | `editor.action.showHover` | `editor::Hover` |

---

### 🪟 5. Window Splits & Directional Navigation
| Action | Keybinding | Neovim | VSCode | Zed Editor |
| :--- | :--- | :--- | :--- | :--- |
| **Split Vertically** | `<leader>sv` | `:vsplit` | `workbench.action.splitEditor` | `pane::SplitRight` |
| **Split Horizontally** | `<leader>sh` | `:split` | `workbench.action.splitEditorOrthogonal` | `pane::SplitDown` |
| **Close Split** | `<leader>sx` | `:close` | `workbench.action.closeActiveEditor` | `pane::CloseActiveItem` |
| **Equalize Splits** | `<leader>se` | `<C-w>=` | `workbench.action.evenEditorWidths` | `pane::ReopenClosedItem` |
| **Focus Left Split** | `<C-h>` | `<C-w>h` | `workbench.action.navigateLeft` | `["workspace::ActivatePaneInDirection", "Left"]` |
| **Focus Lower Split** | `<C-j>` | `<C-w>j` | `workbench.action.navigateDown` | `["workspace::ActivatePaneInDirection", "Down"]` |
| **Focus Upper Split** | `<C-k>` | `<C-w>k` | `workbench.action.navigateUp` | `["workspace::ActivatePaneInDirection", "Up"]` |
| **Focus Right Split** | `<C-l>` | `<C-w>l` | `workbench.action.navigateRight` | `["workspace::ActivatePaneInDirection", "Right"]` |

---

### 🐛 6. Debugger & DAP (`<leader>d...`)
| Action | Keybinding | Neovim (`nvim-dap`) | VSCode | Zed Editor |
| :--- | :--- | :--- | :--- | :--- |
| **Toggle Breakpoint** | `<leader>db` | `dap.toggle_breakpoint` | `workbench.action.debug.toggleBreakpoint` | *(N/A)* |
| **Start / Continue** | `<leader>dc` | `dap.continue` | `workbench.action.debug.start` | *(N/A)* |
| **Toggle Debugger UI** | `<leader>du` | `dapui.toggle` | `workbench.view.debug` | *(N/A)* |

---

## 3. Configuration Blueprints for Each Host

### 🟢 1. Neovim Centralized Hub ([`lua/modules/keymap_registry.lua`](file:///home/addy/.config/nvim/lua/modules/keymap_registry.lua))
Our single-source-of-truth adapter engine dynamically inspects `vim.g.vscode` and binds either the Lua TUI handler or dispatches `vscode.action()`:
```lua
M.bind("toggle_sidebar", "NvimTreeToggle", "workbench.action.toggleSidebarVisibility")
M.bind("focus_tree", toggle_explorer_focus, "workbench.files.action.focusFilesExplorer")
M.bind("find_files", "Telescope find_files", "workbench.action.quickOpen")
M.bind("format_buffer", "Format", "editor.action.formatDocument")
```

---

### 🔵 2. VSCode Configuration (`keybindings.json`)
Open Command Palette $\rightarrow$ **`Preferences: Open Keyboard Shortcuts (JSON)`**:
```json
[
  // 1. Sidebar & Explorer Navigation
  {
    "key": "ctrl+b",
    "command": "workbench.action.toggleSidebarVisibility"
  },
  {
    "key": "space b",
    "command": "workbench.action.toggleSidebarVisibility",
    "when": "editorTextFocus && neovim.init && neovim.mode != 'insert'"
  },
  {
    "key": "space e",
    "command": "workbench.files.action.focusFilesExplorer",
    "when": "editorTextFocus && neovim.init && neovim.mode != 'insert'"
  },
  {
    "key": "space e",
    "command": "workbench.action.focusActiveEditorGroup",
    "when": "sideBarFocus"
  },
  {
    "key": "escape",
    "command": "workbench.action.focusActiveEditorGroup",
    "when": "sideBarFocus"
  }
]
```

---

### 🟠 3. Zed Editor Configuration (`~/.config/zed/keymap.json`)
Open Command Palette $\rightarrow$ **`zed: open keymap`**:
```json
[
  {
    "context": "Editor && vim_mode == normal && !VimWaiting",
    "bindings": {
      // 1. File Explorer & Sidebars
      "space b": "workspace::ToggleLeftDock",
      "space e": "project_panel::ToggleFocus",

      // 2. Finding & Fuzzy Search
      "space f f": "file_finder::Toggle",
      "space f w": "workspace::NewSearch",
      "space f b": "tab_switcher::Toggle",
      "space f s": "project_symbols::Toggle",
      "space c": "command_palette::Toggle",

      // 3. Buffer & File Operations
      "space w": "workspace::Save",
      "space x": "pane::CloseActiveItem",
      "space q": "pane::CloseActiveItem",
      "] b": "pane::ActivateNextItem",
      "[ b": "pane::ActivatePrevItem",

      // 4. Code & Language Tools
      "g d": "editor::GoToDefinition",
      "g D": "editor::GoToDeclaration",
      "g i": "editor::GoToImplementation",
      "g r": "editor::FindAllReferences",
      "shift-k": "editor::Hover",
      "space f m": "editor::Format",
      "space c a": "editor::ToggleCodeActions",
      "space r n": "editor::Rename",
      "] d": "editor::GoToDiagnostic",
      "[ d": "editor::GoToPrevDiagnostic",

      // 5. Splits & Directional Navigation
      "space s v": "pane::SplitRight",
      "space s h": "pane::SplitDown",
      "space s x": "pane::CloseActiveItem",
      "ctrl-h": ["workspace::ActivatePaneInDirection", "Left"],
      "ctrl-j": ["workspace::ActivatePaneInDirection", "Down"],
      "ctrl-k": ["workspace::ActivatePaneInDirection", "Up"],
      "ctrl-l": ["workspace::ActivatePaneInDirection", "Right"]
    }
  }
]
```
