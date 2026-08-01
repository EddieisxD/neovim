# 04 GUI, Terminal & Headless Integration

This document details the integrations for **Neovide GUI**, **VSCode / VSCodium Extension Mode**, **Kitty Remote Terminal Padding Control**, and **Headless Server / Single Instance (`nvr`)**.

---

## 1. Neovide GUI Integration

Located in [`lua/modules/gui.lua`](file:///home/addy/.config/nvim/lua/modules/gui.lua).

### Configuration Options
When Neovide is detected (`vim.g.neovide ~= nil`), the GUI module applies smooth animations, window padding, and font settings:

```lua
if vim.g.neovide then
  vim.g.neovide_opacity = 0.65               -- Glassmorphic window transparency
  vim.g.neovide_padding_top = 24             -- Top window padding
  vim.g.neovide_padding_bottom = 12          -- Bottom window padding
  vim.g.neovide_padding_left = 12            -- Left window padding
  vim.g.neovide_padding_right = 12           -- Right window padding
  vim.g.neovide_cursor_animation_length = 0.08 -- Fluid cursor movement
  vim.g.neovide_cursor_trail_size = 0.8
  vim.g.neovide_cursor_vfx_mode = "railgun"  -- Particle effects
  vim.g.neovide_remember_window_size = false
  vim.g.neovide_confirm_quit = true

  vim.opt.guifont = "JetBrainsMono Nerd Font:h13"
end
```

---

## 2. VSCode / VSCodium Keymap Adapter Engine

Located in [`lua/modules/keymap_registry.lua`](file:///home/addy/.config/nvim/lua/modules/keymap_registry.lua).

### Architectural Problem & Solution
When Neovim runs embedded inside VSCode or VSCodium via the `vscode-neovim` extension, standard Neovim TUI commands (like `:bdelete`, `:NvimTreeToggle`, `:Telescope`) fail because VSCode owns the tab bar, sidebar Explorer, and search windows.

Our **Centralized Keymap Registry (`keymap_registry.bind`)** automatically maps semantic actions to Neovim Lua functions in TUI mode, or to VSCode native actions (`require("vscode").action(...)`) when running in VSCodium:

```lua
-- Single Source of Truth
M.bind("close_buffer",  "bdelete",              "workbench.action.closeActiveEditor")
M.bind("toggle_tree",   "NvimTreeToggle",       "workbench.action.toggleSidebarVisibility")
M.bind("focus_tree",    "NvimTreeFocus",        "workbench.files.action.focusFilesExplorer")
M.bind("find_files",    "Telescope find_files", "workbench.action.quickOpen")
M.bind("live_grep",     "Telescope live_grep",  "workbench.action.findInFiles")
M.bind("save_file",     "w",                    "workbench.action.files.save")
```

---

## 3. Kitty Remote Terminal Padding Engine

Located in [`lua/modules/kitty.lua`](file:///home/addy/.config/nvim/lua/modules/kitty.lua).

### How it Works
When running inside Kitty terminal (`$KITTY_WINDOW_ID` present):
1. **Startup (`UIEnter` / `VimEnter`)**: Executes `kitty @ set-spacing padding=0 margin=0` via non-blocking detached `vim.system`, removing Kitty's outer window padding.
2. **Internal Neovim Padding**: Uses Neovim internal options (`opt.signcolumn = "yes:2"`, `opt.foldcolumn = "1"`) to maintain crisp text spacing.
3. **Exit (`VimLeavePre`)**: Executes `kitty @ set-spacing padding=default margin=default` to restore Kitty's original terminal padding when quitting Neovim.
4. **Socket Protection Guard**: Checks `$KITTY_LISTEN_ON` before running `kitty @` commands, preventing `open /dev/tty: no such device or address` timeouts when remote control is disabled.

---

## 4. Single Instance Server & Headless Integration (`nvr`)

### Headless Mode (`nvim --headless`)
Neovim can run headless as an embedded RPC server or for command-line batch operations (e.g. running unit tests via `nvim --headless -u init.lua -c "luafile tests/run_tests.lua" +q`).

### Single Instance Multiplexing (`neovim-remote` / `nvr`)
To open files inside an existing Neovim instance from external terminals, Kitty windows, or Git sub-shells without spawning new Neovim processes:
- Set `export VISUAL="nvr -cc split --remote-wait"` or `export EDITOR="nvr --remote-wait"`.
- Uses Neovim's UNIX domain socket (`$NVIM_LISTEN_ADDRESS` or `vim.v.servername`).
