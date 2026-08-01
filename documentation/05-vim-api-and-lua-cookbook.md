# 05 Neovim Lua API Index & Cookbook

This document serves as a comprehensive developer reference and recipe book for Neovim Lua APIs (`vim.api.*`, `vim.fn.*`, `vim.opt.*`, `vim.diagnostic.*`, `vim.lsp.*`).

---

## 1. Core Neovim Lua API Taxonomy

### `vim.api.*` (C Engine Bindings)
High-performance C-level primitives for buffers, windows, tabs, highlights, and autocommands:

| Function | Description |
| :--- | :--- |
| **`vim.api.nvim_create_user_command(name, command, opts)`** | Create a custom user command (e.g. `:Lsp`, `:Formatter`, `:Linter`, `:Dap`) |
| **`vim.api.nvim_create_augroup(name, opts)`** | Create or clear an autocommand group |
| **`vim.api.nvim_create_autocmd(events, opts)`** | Register an autocommand hook (`FileType`, `BufWritePost`, `VimEnter`, `ColorScheme`) |
| **`vim.api.nvim_set_hl(ns_id, name, val)`** | Define or override a highlight group (e.g., `vim.api.nvim_set_hl(0, "MsgArea", { link = "Normal" })`) |
| **`vim.api.nvim_get_hl(ns_id, opts)`** | Inspect existing highlight group definitions |
| **`vim.api.nvim_open_win(buffer, enter, config)`** | Create a floating or split window |
| **`vim.api.nvim_get_current_buf()`** | Get integer buffer ID of active buffer |
| **`vim.api.nvim_list_wins()`** | Get list of all open window handles |

### `vim.fn.*` (Vimscript Functions)
Exposes all legacy Vimscript functions to Lua:

| Function | Description |
| :--- | :--- |
| **`vim.fn.executable("git")`** | Returns `1` if binary exists on `$PATH`, `0` otherwise |
| **`vim.fn.findfile(".envrc", ".;")`** | Upward ancestor file search (`.;` operator) |
| **`vim.fn.isdirectory("/tmp/neovim")`** | Check if directory exists |
| **`vim.fn.mkdir(path, "p")`** | Create directory recursively |
| **`vim.fn.system(cmd)`** | Execute shell command synchronously |

### `vim.opt.*` & `vim.o.*` (Vim Options)
- **`vim.o`**: Access options via standard scalar types (`vim.o.cmdheight = 1`).
- **`vim.opt`**: Access options via rich Lua table interfaces (`opt.clipboard:append("unnamedplus")`, `opt.fillchars:append({ eob = " " })`).

---

## 2. Lua Cookbook & Useful Recipes

### Recipe 1: Smart Floating Window Dismissal (`<Esc>`)
Closes all open floating windows (LSP Hover, Diagnostics) and clears search highlights:
```lua
vim.keymap.set("n", "<Esc>", function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config and config.relative and config.relative ~= "" then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  vim.cmd("nohlsearch")
end, { desc = "Close floating windows and clear search highlights" })
```

### Recipe 2: All-or-Nothing UI Transparency
Clears background color (`bg = "none"`) across all UI elements:
```lua
local groups = {
  "Normal", "NormalNC", "NormalFloat", "FloatBorder",
  "SignColumn", "LineNr", "FoldColumn", "StatusLine",
  "NvimTreeNormal", "TelescopeNormal", "Pmenu",
}

for _, g in ipairs(groups) do
  vim.api.nvim_set_hl(0, g, { bg = "none" })
end
```

### Recipe 3: Dynamic Command Suite with Tab Completion
Creates a unified `:Command <subcommand>` user command with completion:
```lua
local subcommands = { "enable", "disable", "toggle", "info" }

vim.api.nvim_create_user_command("MyTool", function(opts)
  local args = vim.split(opts.args, "%s+", { trimempty = true })
  local sub = args[1]
  if sub == "enable" then ... end
end, {
  nargs = "*",
  complete = function(arg_lead, cmd_line)
    local matches = {}
    for _, sub in ipairs(subcommands) do
      if sub:find(arg_lead, 1, true) == 1 then table.insert(matches, sub) end
    end
    return matches
  end,
})
```

### Recipe 4: Buffer-Matching Bottom Command Line Row
Prevents statusline overwriting while maintaining seamless buffer background colors:
```lua
vim.o.cmdheight = 1
vim.api.nvim_set_hl(0, "MsgArea", { link = "Normal" })
```
