--- Modular DAG-based Neovim Architecture
--- Entrypoint: init.lua

-- Set global leader keys BEFORE any plugin loaders initialize (required by lazy.nvim)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable bytecode caching for fast startup
if vim.loader then
    vim.loader.enable()
end

-- Ensure root configuration directory is on runtimepath
local current_file = debug.getinfo(1, "S").source:sub(2)
local root_dir = vim.fn.fnamemodify(current_file, ":p:h")
if not vim.tbl_contains(vim.opt.rtp:get(), root_dir) then
    vim.opt.rtp:prepend(root_dir)
end

-- 1. Load meta.lua (located in lua/meta.lua)
local Bundle = require("meta")

-- 2. Load Control Plane Settings from lua/settings.lua
local settings_path = Bundle.meta.config_dir .. "/lua/settings.lua"
local ok_settings, settings = pcall(dofile, settings_path)
if not ok_settings then
    settings = {
        loader = "lazy",
        plugin_source = "auto",
        log_level = "INFO",
        strict_mode = true,
        modules = { options = true, keymaps = true, autocmds = true },
    }
end

-- 3. Initialize Bundle with control plane settings (Pure phase)
Bundle:init(settings)

-- 4. Discover and register all modules
local modules_loader = require("modules")
modules_loader.load_all(Bundle)

-- 5. Execute DAG Pipeline (Side-effect phase & logging)
local stats = Bundle:execute()

-- 6. Define Diagnostic Commands
vim.api.nvim_create_user_command("DagStatus", function()
    print(
        string.format("DAG Status: %d executed, %d failed in %.2fms", stats.executed, stats.failed, stats.total_time_ms)
    )
end, { desc = "Show DAG execution statistics" })

vim.api.nvim_create_user_command("DagLog", function()
    local logs = Bundle.logger.get_logs()
    local lines = {}
    for _, entry in ipairs(logs) do
        table.insert(lines, string.format("[%s] [%s] %s", entry.time, entry.level, entry.message))
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_cmd({ cmd = "sbuffer", args = { tostring(buf) } }, {})
end, { desc = "Open DAG execution log in buffer" })

vim.api.nvim_create_user_command("BundleInfo", function()
    print("Loader: " .. tostring(Bundle.settings.loader))
    print("Plugin Source: " .. tostring(Bundle.settings.plugin_source))
    print("Is Nix: " .. tostring(Bundle.meta.is_nix))
    print("Registered Modules: " .. vim.tbl_count(Bundle.modules))
    print("Registered Specs: " .. #Bundle.specs)
end, { desc = "Display global Bundle diagnostic information" })
