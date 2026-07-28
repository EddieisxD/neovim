# Control Plane Configuration (`lua/settings.lua`)

The control plane file [`lua/settings.lua`](file:///home/addy/.config/nvim.wip/lua/settings.lua) is the single point of control for enabling/disabling modules, selecting plugin loaders, choosing plugin store sources, and configuring logging.

---

## Configuration Options

```lua
local M = {}

--- Plugin Loader choice: "lazy" | "lze" | "none"
M.loader = "lazy"

--- Plugin download source: "auto" | "nix" | "traditional"
--- - "auto": Automatically detects if running under Nix
--- - "nix": Resolves store paths from Nix environment
--- - "traditional": Uses standard git downloading via plugin manager
M.plugin_source = "auto"

--- Global log level: "TRACE" | "DEBUG" | "INFO" | "WARN" | "ERROR"
M.log_level = "INFO"

--- Strict metatable locking
M.strict_mode = true

--- Active Modules List
--- Setting a module to `false` disables it from being registered in the DAG
M.modules = {
  options     = true,
  keymaps     = true,
  autocmds    = true,
  colorscheme = true,
  treesitter  = true,
  lsp         = true,
  telescope   = true,
}

return M
```

---

## Behavior Matrix

| Option | Value | Behavior |
| :--- | :--- | :--- |
| `loader` | `"lazy"` | Uses `lazy.nvim` adapter to manage plugin loading & lazy events |
| `loader` | `"lze"` | Uses `lze` adapter to manage plugin loading & lazy events |
| `loader` | `"none"` | Skips third-party plugin managers; runs inline plugin configs directly |
| `plugin_source` | `"auto"` | Checks `vim.g.nix_info_plugin_name`, `_G.nixInfo`, or RTP for Nix store paths |
| `plugin_source` | `"nix"` | Forces Nix store path resolution for all plugins |
| `plugin_source` | `"traditional"`| Forces standard git cloning & plugin manager directory management |
