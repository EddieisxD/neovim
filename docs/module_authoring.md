# Module Authoring Guide

This guide explains how to create, structure, and edit modules in the `lua/modules/` directory.

---

## Zero-Manifest Module Discovery

You **never** need to manually register a new module in a list or edit `init.lua`. The loader ([`lua/modules/init.lua`](file:///home/addy/.config/nvim.wip/lua/modules/init.lua)) automatically scans `lua/modules/` recursively on startup.

Simply create a `.lua` file inside `lua/modules/` or any subdirectory, return a valid module table, and it will be picked up automatically!

---

## Standard Module Anatomy

A module file returns a single Lua table with the following structure:

```lua
--- lua/modules/plugins/gitsigns.lua
local dag_lib = require("library.dag")

return {
  -- 1. Unique Module Identifier (Required)
  id = "gitsigns",

  -- 2. Execution Phase (Required)
  phase = dag_lib.Phases.PLUGINS,

  -- 3. Prerequisites / Dependencies (Optional)
  deps = { "options", "keymaps" },

  -- 4. Plugin Specifications Array (Optional)
  specs = {
    {
      name = "lewis6991/gitsigns.nvim",
      id = "gitsigns",
      event = { "BufReadPre", "BufNewFile" },

      keys = {
        { "]h", "<cmd>Gitsigns next_hunk<cr>", desc = "Next Git Hunk" },
        { "[h", "<cmd>Gitsigns prev_hunk<cr>", desc = "Prev Git Hunk" },
      },

      opts = {
        signs = {
          add = { text = "│" },
          change = { text = "│" },
        },
      },
    },
  },

  -- 5. Module Execution Function (Optional)
  -- Executed in side-effect phase by the DAG engine
  exec = function()
    -- Any side-effectful setup (vim.opt, vim.keymap.set, custom logic)
  end,
}
```

---

## Organizing Modules

You can organize your modules in subdirectories based on concern:

```
lua/modules/
├── options.lua                # General vim options
├── keymaps.lua                # General keymaps
├── autocmds.lua               # General autocommands
└── plugins/
    ├── colorscheme.lua        # Theme & UI
    ├── treesitter.lua         # Treesitter syntax
    ├── lsp.lua                # Language server configs
    ├── telescope.lua          # Fuzzy finder
    └── git.lua                # Git integration plugins
```

- Any file in `lua/modules/` or subfolders (except `init.lua`) is loaded automatically.
- Subfolder structures (e.g. `lua/modules/plugins/git.lua`) map to require path `modules.plugins.git`.
