--- Dynamic Module Loader
--- Automatically scans lua/modules/ recursively and registers all module files.

local M = {}

--- Recursively scan a directory for .lua files
---@param dir string Absolute directory path
---@param base_dir string Root lua/modules directory path
---@return string[] Array of require module paths
local function scan_modules_dir(dir, base_dir)
  local modules = {}
  local handle = vim.loop.fs_scandir(dir)

  if not handle then return modules end

  while true do
    local name, type_name = vim.loop.fs_scandir_next(handle)
    if not name then break end

    local full_path = dir .. "/" .. name

    if type_name == "directory" then
      local sub_modules = scan_modules_dir(full_path, base_dir)
      for _, mod in ipairs(sub_modules) do
        table.insert(modules, mod)
      end
    elseif type_name == "file" and name:match("%.lua$") and name ~= "init.lua" then
      -- Compute relative path from base_dir: e.g. /path/lua/modules/plugins/lsp.lua -> modules.plugins.lsp
      local rel_path = full_path:sub(#base_dir + 2):gsub("%.lua$", ""):gsub("/", ".")
      table.insert(modules, "modules." .. rel_path)
    end
  end

  return modules
end

--- Load and register all discovered modules into Bundle
---@param bundle table Global Bundle object
function M.load_all(bundle)
  local settings = bundle.settings or {}
  local enabled = settings.modules or {}
  local modules_dir = bundle.meta.config_dir .. "/lua/modules"

  bundle.logger.info("[Module Registry] Dynamically scanning lua/modules/ directory...")

  local module_paths = scan_modules_dir(modules_dir, modules_dir)
  table.sort(module_paths)

  for _, mod_path in ipairs(module_paths) do
    local ok, mod = pcall(require, mod_path)
    if ok and type(mod) == "table" and mod.id then
      -- Automatically register unless explicitly set to false in settings.lua
      if enabled[mod.id] ~= false then
        bundle:register_module(mod)
      else
        bundle.logger.info(string.format("[Module Registry] Module '%s' disabled in settings.lua", mod.id))
      end
    else
      bundle.logger.warn(string.format("[Module Registry] Failed to load module path '%s': %s", mod_path, tostring(mod)))
    end
  end

  bundle.logger.info(string.format("[Module Registry] Successfully registered %d modules dynamically", vim.tbl_count(bundle.modules)))
end

return M
