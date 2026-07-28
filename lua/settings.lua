--- Control Plane Settings
--- Controls feature flags, loader choice, plugin sources, and active modules.

local M = {}

--- Loader choice: "lazy" | "lze" | "none"
M.loader = "lazy"

--- Plugin download source: "auto" | "nix" | "traditional"
--- - "auto": Detects automatically if Nix is present
--- - "nix": Resolves all plugin store paths from Nix environment
--- - "traditional": Uses standard git cloning / plugin manager downloads
M.plugin_source = "auto"

--- Global log level: "TRACE" | "DEBUG" | "INFO" | "WARN" | "ERROR"
M.log_level = "INFO"

--- Enforce strict metatable locking on configuration tables
M.strict_mode = true

--- Active Modules List (Control plane toggles)
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
