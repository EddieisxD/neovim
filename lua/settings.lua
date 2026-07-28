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

--- Transparency Toggle (Default State)
M.transparent = true           -- Enable/disable full UI transparency

--- Formatting & Tooling Toggles
M.format_on_save = true        -- Automatically format buffers on save
M.auto_attach_lsp = true       -- Dynamically attach LSPs found on $PATH
M.auto_attach_formatter = true -- Dynamically attach formatters found on $PATH
M.auto_attach_linter = true    -- Dynamically attach linters found on $PATH

--- Active Modules List (Control plane toggles)
M.modules = {
  options         = true,
  keymaps         = true,
  autocmds        = true,
  colorscheme     = true,
  transparency    = true,
  treesitter      = true,
  direnv          = true,
  lsp             = true,
  formatter       = true,
  linter          = true,
  telescope       = true,
  blink_cmp       = true,
  file_explorer   = true,
  render_markdown = true,
  lualine         = true,
  fidget          = true,
  mason           = true,
  autopairs       = true,
  which_key       = true,
}

return M
