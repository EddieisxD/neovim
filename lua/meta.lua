local meta = {}

-- Setup Runtime Path and package.path for standalone / WIP initialization
local current_file = debug.getinfo(1, "S").source:sub(2)
local root_dir = vim.fn.fnamemodify(current_file, ":p:h:h")
if not vim.tbl_contains(vim.opt.rtp:get(), root_dir) then
  vim.opt.rtp:prepend(root_dir)
end
local lua_path = root_dir .. "/lua/?.lua;" .. root_dir .. "/lua/?/init.lua;" .. root_dir .. "/?.lua;" .. root_dir .. "/?/init.lua;"
package.path = lua_path .. package.path

local metatable_util = require("library.metatable")
local logger = require("library.logger")
local dag_lib = require("library.dag")
local loader_adapter = require("library.loader_adapter")

-- Environment Detection
meta.is_nix = vim.g.nix_info_plugin_name ~= nil or os.getenv("NIX_STORE") ~= nil
meta.config_dir = root_dir
meta.strict_table = metatable_util.strict_table
meta.seal = metatable_util.seal

-- Nix compatibility setup
if vim.g.nix_info_plugin_name then
  local ok, nix_mod = pcall(require, vim.g.nix_info_plugin_name)
  if ok then
    _G.nixInfo = nix_mod
  end
end

if not _G.nixInfo then
  _G.nixInfo = setmetatable({}, {
    __call = function(_, default) return default end
  })
end

_G.nixInfo.isNix = vim.g.nix_info_plugin_name ~= nil or os.getenv("NIX_STORE") ~= nil

function _G.nixInfo.get_nix_plugin_path(name)
  if type(_G.nixInfo) == "function" or getmetatable(_G.nixInfo) then
    local path = _G.nixInfo(nil, "plugins", "lazy", name)
              or _G.nixInfo(nil, "plugins", "start", name)
              or _G.nixInfo(nil, "plugins", "specs", name)
    if path then return path end
  end
  return nil
end

--- Bundle Table Construction
local Bundle = {
  meta = meta,
  settings = {},
  modules = {},
  specs = {},
  dag = dag_lib.new(),
  logger = logger,
  loader_adapter = loader_adapter,
  _initialized = false,
  _sealed = false,
}

--- Initialize Bundle with Control Plane Settings
---@param settings table
function Bundle:init(settings)
  assert(type(settings) == "table", "[Bundle] Settings must be a table")

  self.settings = settings
  logger.set_level(settings.log_level or "INFO")

  logger.info("[Bundle Init] Initializing configuration bundle...")
  logger.debug("[Bundle Init] Settings: " .. vim.inspect(settings))

  self._initialized = true
  return self
end

--- Register a configuration module
---@param mod { id: string, phase?: number, deps?: string[], specs?: table[], exec?: function }
function Bundle:register_module(mod)
  assert(mod.id, "[Bundle] Module registration requires an 'id'")

  if self.modules[mod.id] then
    logger.warn(string.format("[Bundle] Overwriting registered module '%s'", mod.id))
  end

  self.modules[mod.id] = mod

  -- Register any plugin specs included in the module
  if mod.specs then
    for _, s in ipairs(mod.specs) do
      self:register_spec(s)
    end
  end

  logger.debug(string.format("[Bundle] Registered module: '%s'", mod.id))
end

--- Register a plugin specification
---@param spec_tbl table
function Bundle:register_spec(spec_tbl)
  local s = loader_adapter.spec(spec_tbl)
  table.insert(self.specs, s)
  logger.debug(string.format("[Bundle] Registered plugin spec: '%s'", s.name))
end

--- Build DAG nodes from registered modules and specs
function Bundle:build_dag()
  assert(self._initialized, "[Bundle] Must call Bundle:init(settings) before building DAG")
  logger.info("[Bundle DAG] Building execution graph...")

  -- 1. Create DAG nodes for registered modules
  for id, mod in pairs(self.modules) do
    if mod.exec then
      self.dag:add_node({
        id = id,
        phase = mod.phase or dag_lib.Phases.SETUP,
        deps = mod.deps or {},
        exec = mod.exec,
        meta = { type = "module" },
      })
    end
  end

  -- 2. Create DAG node for Plugin Loader phase
  self.dag:add_node({
    id = "system.plugin_loader",
    phase = dag_lib.Phases.LOADER,
    deps = { "options" }, -- Runs after options are set
    exec = function()
      loader_adapter.setup_loader(self.settings.loader, self.specs, self.settings)
    end,
    meta = { type = "loader" },
  })

  logger.info(string.format("[Bundle DAG] Graph constructed with %d nodes", vim.tbl_count(self.dag.nodes)))
end

--- Seal configuration tables to prevent accidental modification before side-effect execution
function Bundle:seal_configuration()
  if self.settings.strict_mode and not self._sealed then
    self.modules = meta.seal(self.modules, "Bundle.modules")
    self.specs = meta.seal(self.specs, "Bundle.specs")
    self._sealed = true
    logger.info("[Bundle] Configuration tables sealed with metatable locks")
  end
end

--- Run DAG side-effect execution
---@return table Execution statistics
function Bundle:execute()
  self:build_dag()
  self:seal_configuration()

  logger.info("[Bundle Execution] Commencing side-effect execution phase...")
  local stats = self.dag:execute()
  logger.info("[Bundle Execution] DAG execution completed cleanly")
  return stats
end

-- Export global _G.Bundle
_G.Bundle = meta.strict_table(Bundle, "Bundle", { allow_extension = true })

return Bundle
