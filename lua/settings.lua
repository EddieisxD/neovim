--- Control Plane Settings
--- Controls feature flags, loader choice, plugin sources, and active modules.

local M = {}

--- Loader choice: "lazy" | "lze" | "none"
M.loader = "lazy"

--- Plugin download source: "auto" | "nix" | "traditional"
M.plugin_source = "auto"

--- Global log level: "TRACE" | "DEBUG" | "INFO" | "WARN" | "ERROR"
M.log_level = "INFO"

--- Enforce strict metatable locking on configuration tables
M.strict_mode = true

--- Formatting & Tooling Toggles
M.format_on_save = true        -- Automatically format buffers on save
M.auto_attach_lsp = true       -- Dynamically attach LSPs found on $PATH
M.auto_attach_formatter = true -- Dynamically attach formatters found on $PATH
M.auto_attach_linter = true    -- Dynamically attach linters found on $PATH

--- Active Modules List (Control plane toggles)
M.modules = {
  options     = true,
  keymaps     = true,
  autocmds    = true,
  colorscheme = true,
  treesitter  = true,
  lsp         = true,
  formatter   = true,
  linter      = true,
  telescope   = true,
}

return M
