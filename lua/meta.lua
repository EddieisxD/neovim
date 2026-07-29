--- Meta Core Framework Engine
--- Manages global Bundle initialization, 3-tier data architecture, table sealing, and persistent state.

local meta = {}

-- Setup Runtime Path and package.path for standalone / WIP initialization
local current_file = debug.getinfo(1, "S").source:sub(2)
local root_dir = vim.fn.fnamemodify(current_file, ":p:h:h")
if not vim.tbl_contains(vim.opt.rtp:get(), root_dir) then
  vim.opt.rtp:prepend(root_dir)
end
local lua_path = root_dir .. "/lua/?.lua;" .. root_dir .. "/lua/?/init.lua;" .. root_dir .. "/?.lua;" .. root_dir .. "/?/init.lua;"
package.path = lua_path .. package.path

-- Prepend Mason binary directory to PATH if it exists (Mason fallback in traditional mode)
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if vim.fn.isdirectory(mason_bin) == 1 and not vim.env.PATH:find(mason_bin, 1, true) then
  vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
end

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

local Bundle = {
  meta = meta,
  settings = {},
  defaults = {
    colorscheme = "catppuccin-mocha",
    transparent = true,
    number = true,
    relativenumber = true,
  },
  state = {},
  modules = {},
  specs = {},
  dag = dag_lib.new(),
  logger = logger,
  _initialized = false,
}

--- Get filepath for persistent runtime state based on isolation setting ("strict" | "tmp" | "flexible")
function Bundle:get_state_filepath()
  local mode = self.settings and self.settings.isolation or "flexible"
  if mode == "strict" then
    return nil -- Zero disk persistence
  elseif mode == "tmp" then
    local tmp_dir = "/tmp/neovim"
    if vim.fn.isdirectory(tmp_dir) == 0 then
      vim.fn.mkdir(tmp_dir, "p")
    end
    return tmp_dir .. "/bundle_state.json"
  else -- "flexible" (default)
    local state_dir = vim.fn.stdpath("state")
    if vim.fn.isdirectory(state_dir) == 0 then
      vim.fn.mkdir(state_dir, "p")
    end
    return state_dir .. "/bundle_state.json"
  end
end

--- Load persistent runtime state from disk
function Bundle:load_state()
  local filepath = self:get_state_filepath()
  if not filepath then
    logger.info("[Bundle State] Strict isolation mode: using in-memory defaults.")
    self.state = vim.tbl_deep_extend("force", self.state or {}, {
      colorscheme = self.settings.colorscheme or self.defaults.colorscheme,
      transparent = self.settings.transparent ~= false,
      number = self.settings.number ~= false,
      relativenumber = self.settings.relativenumber ~= false,
    })
    return
  end

  local f = io.open(filepath, "r")
  if f then
    local content = f:read("*a")
    f:close()
    if content and #content > 0 then
      local ok, decoded = pcall(vim.json.decode, content)
      if ok and type(decoded) == "table" then
        logger.info("[Bundle State] Successfully loaded state from " .. filepath)
        self.state = vim.tbl_deep_extend("force", self.state or {}, decoded)
        return
      end
    end
  end

  -- Initialize from defaults / settings if state file does not exist
  logger.info("[Bundle State] State file missing. Initializing from Bundle.defaults...")
  self.state = vim.tbl_deep_extend("force", self.state or {}, {
    colorscheme = self.settings.colorscheme or self.defaults.colorscheme,
    transparent = self.settings.transparent ~= false,
    number = self.settings.number ~= false,
    relativenumber = self.settings.relativenumber ~= false,
  })
  self:save_state()
end

--- Persist runtime state to disk for cross-session survival
function Bundle:save_state()
  local filepath = self:get_state_filepath()
  if not filepath then return end

  local data = {
    colorscheme = self.state.colorscheme,
    transparent = self.state.transparent,
    number = self.state.number,
    relativenumber = self.state.relativenumber,
  }
  local ok, encoded = pcall(vim.json.encode, data)
  if ok then
    local f = io.open(filepath, "w")
    if f then
      f:write(encoded)
      f:close()
      logger.debug("[Bundle State] Saved persistent state to " .. filepath)
    end
  end
end

--- Decoupled Notification Bridge enforcing Atomic Module Isolation
--- Routes notifications through vim.notify (intercepted by Fidget if active)
function Bundle:notify(msg, level, opts)
  level = level or vim.log.levels.INFO
  if type(opts) == "string" then
    opts = { title = opts }
  end
  vim.notify(msg, level, opts or {})
end

--- Initialize Bundle with Control Plane Settings
---@param settings table
function Bundle:init(settings)
  assert(type(settings) == "table", "[Bundle] Settings must be a table")

  self.settings = settings
  logger.set_level(settings.log_level or "INFO")

  logger.info("[Bundle Init] Initializing configuration bundle...")
  logger.debug("[Bundle Init] Settings: " .. vim.inspect(settings))

  -- Load or initialize persistent state
  self:load_state()

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

  -- Wrap module execution into a DAG node
  local exec_fn = mod.exec or function() end
  self.dag:add_node({
    id = mod.id,
    phase = mod.phase or dag_lib.Phases.PLUGINS,
    deps = mod.deps or {},
    exec = function()
      logger.info(string.format("[Module Execution] Phase %d: Running module '%s'", mod.phase or dag_lib.Phases.PLUGINS, mod.id))
      exec_fn()
    end,
  })
end

--- Register a raw plugin spec
---@param spec table
function Bundle:register_spec(spec)
  local normalized = loader_adapter.spec(spec)
  table.insert(self.specs, normalized)
end

--- Execute the full DAG execution pipeline
function Bundle:execute()
  assert(self._initialized, "[Bundle] Must call Bundle:init(settings) before Bundle:execute()")

  logger.info("[Bundle Pipeline] Preparing plugin loader specs...")
  loader_adapter.setup_loader(self.settings.loader or "lazy", self.specs, self.settings)

  logger.info("[Bundle Pipeline] Executing DAG topological graph...")
  local stats = self.dag:execute()
  logger.info(string.format("[Bundle Pipeline] Pipeline finished: %d executed, %d failed in %.2fms",
    stats.executed, stats.failed, stats.total_time_ms))

  return stats
end

return Bundle
