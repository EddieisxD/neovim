# Loader Adapters & Universal Plugin Specifications

The loader adapter ([`library/loader_adapter.lua`](file:///home/addy/.config/nvim.wip/library/loader_adapter.lua)) provides a **universal plugin specification DSL**. You write your plugin specs once, and the adapter handles converting them for `lazy.nvim` or `lze` seamlessly.

---

## Universal Plugin Spec Schema

```lua
{
  name = "nvim-telescope/telescope.nvim", -- Plugin repo or name
  id = "telescope",                       -- Short identifier
  nix_name = "telescope-nvim",            -- (Optional) Override Nix store package name
  deps = { "nvim-lua/plenary.nvim" },     -- Dependencies
  event = { "VimEnter" },                 -- Lazy-load events
  cmd = { "Telescope" },                  -- Lazy-load user commands
  ft = { "lua", "python" },               -- Lazy-load filetypes
  keys = {                                -- Lazy-load keybindings
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
  },

  -- Lifecycle Hooks
  before = function() ... end,            -- Pre-load hook (runs before plugin loads)
  config = function() ... end,            -- Setup / config function
  opts = { ... },                         -- Table passed to require(id).setup(opts)
  after = function() ... end,             -- Post-load hook (runs after plugin setup)

  lazy = true,                            -- Force lazy loading
  enabled = true,                         -- Enable/disable spec
  auto_enable = true,                     -- Nix-specific auto-enable flag
}
```

---

## Hook & Keymap Adapter Mapping

| Universal Spec Field | `lazy.nvim` Target Field | `lze` Target Field | Description |
| :--- | :--- | :--- | :--- |
| `keys` | `keys` | `keys` | Keymap table; lazy-loads plugin on keypress |
| `before` / `init` | `init` | `before` | Function executed before plugin loads |
| `config` / `load` | `config` | `load` | Main setup function |
| `opts` | Passed to `setup(opts)` | Passed to `setup(opts)` | Options table |
| `after` / `post` | Wrapped in `config` | `after` | Function executed after plugin setup finishes |

---

## Nix vs. Traditional Path Resolution

1. If `plugin_source` is set to `"nix"` or `"auto"` (under a Nix environment):
   - The adapter checks `_G.nixInfo.get_nix_plugin_path(name)` or Neovim's runtime path (`pack/*/*/<plugin_name>`).
   - If found, it injects `dir = nix_path` into the spec table so the loader consumes the local Nix store package directly without attempting git network fetches.
2. If `plugin_source` is `"traditional"`:
   - The spec passes repo strings (`"nvim-telescope/telescope.nvim"`) to Lazy or Lze to handle cloning and updates automatically.
