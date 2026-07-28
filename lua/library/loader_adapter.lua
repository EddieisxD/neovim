--- Loader Adapter: Converts Universal Plugin Specs into Lazy.nvim or Lze Specs
--- Handles Nix store path resolution vs Traditional git plugin downloads.

local logger = require("library.logger")

local M = {}

--- Create a universal plugin specification helper
---@param tbl table
---@return table
function M.spec(tbl)
  assert(type(tbl) == "table", "[Spec] Spec must be a table")
  assert(tbl.name or tbl[1], "[Spec] Plugin spec must specify a name or repo")

  local s = vim.deepcopy(tbl)
  s.name = s.name or s[1]
  s.id = s.id or s.name:match("([^/]+)$"):gsub("%.nvim$", "")
  s.deps = s.deps or s.dependencies or {}
  s.enabled = s.enabled ~= false

  return s
end

--- Resolve plugin location under Nix environment
---@param plugin_name string
---@return string|nil
function M.resolve_nix_path(plugin_name)
  local name_variants = {
    plugin_name,
    plugin_name:gsub("%.nvim$", ""),
    plugin_name:gsub("%-nvim$", ""),
    plugin_name .. "-nvim",
    (plugin_name:gsub("%-", ".")),
  }

  -- 1. Check nixInfo global standard
  if _G.nixInfo and type(_G.nixInfo.get_nix_plugin_path) == "function" then
    for _, var in ipairs(name_variants) do
      local path = _G.nixInfo.get_nix_plugin_path(var)
      if path then return path end
    end
  end

  -- 2. Check global nix_plugin_dir option
  if vim.g.nix_plugin_dir then
    for _, var in ipairs(name_variants) do
      local path = vim.g.nix_plugin_dir .. "/" .. var
      if vim.fn.isdirectory(path) == 1 then return path end
    end
  end

  -- 3. Check Neovim RTP for pre-loaded Nix store plugins
  for _, var in ipairs(name_variants) do
    local matches = vim.api.nvim_get_runtime_file("pack/*/*/" .. var, false)
    if #matches > 0 then
      return matches[1]
    end
  end

  return nil
end

local metatable_util = require("library.metatable")

--- Adapt universal specs for Lazy.nvim
---@param specs table[]
---@param settings table
---@return table[]
function M.to_lazy_specs(specs, settings)
  local lazy_specs = {}

  for _, spec_orig in ipairs(specs) do
    local s = metatable_util.unseal(spec_orig)
    if s.enabled then
      local lazy_spec = {
        s.name,
        lazy = s.lazy,
        cmd = s.cmd,
        event = s.event,
        ft = s.ft,
        keys = s.keys,
        opts = s.opts,
        build = s.build,
        init = s.before or s.init,
      }

      -- Pre/Post hook mapping for Lazy
      local user_config = s.config
      local user_after = s.after or s.post

      if user_config or user_after or s.opts then
        lazy_spec.config = function(plugin, opts)
          if s.opts then
            local ok, p = pcall(require, s.id or s.name:match("([^/]+)$"))
            if ok and p.setup then
              p.setup(opts or s.opts)
            end
          end
          if type(user_config) == "function" then
            user_config(plugin, opts)
          end
          if type(user_after) == "function" then
            user_after(plugin, opts)
          end
        end
      end

      -- Dependency handling
      if #s.deps > 0 then
        lazy_spec.dependencies = s.deps
      end

      -- Nix vs Traditional adaptation
      local is_nix = (settings.plugin_source == "nix") or
          (settings.plugin_source == "auto" and (_G.nixInfo and _G.nixInfo.isNix))

      if is_nix then
        local nix_name = s.nix_name or s.name:match("([^/]+)$")
        local nix_path = M.resolve_nix_path(nix_name)
        if nix_path then
          lazy_spec.dir = nix_path
          logger.debug(string.format("[Lazy Adapter] Resolved Nix path for '%s' -> '%s'", s.name, nix_path))
        else
          logger.warn(string.format("[Lazy Adapter] Nix path not found for '%s', relying on Lazy fallback", s.name))
        end
      end

      table.insert(lazy_specs, lazy_spec)
    end
  end

  return lazy_specs
end

--- Adapt universal specs for Lze (or lz.n)
---@param specs table[]
---@param settings table
---@return table[]
function M.to_lze_specs(specs, settings)
  local lze_specs = {}

  for _, spec_orig in ipairs(specs) do
    local s = metatable_util.unseal(spec_orig)
    if s.enabled then
      local lze_spec = {
        name = s.id or s.name:match("([^/]+)$"),
        cmd = s.cmd,
        event = s.event,
        ft = s.ft,
        keys = s.keys,
        auto_enable = s.auto_enable,
        before = s.before or s.init,
        after = s.after or s.post,
      }

      -- Lze uses `dep` for dependencies
      if #s.deps > 0 then
        lze_spec.dep = s.deps
      end

      -- Lze uses `load` for configuration callback
      local user_config = s.config or s.load
      if user_config or s.opts then
        lze_spec.load = function(name)
          if s.opts then
            local ok, p = pcall(require, name)
            if ok and p.setup then
              p.setup(s.opts)
            end
          end
          if type(user_config) == "function" then
            user_config(name)
          end
        end
      end

      -- Nix path override for Lze
      local is_nix = (settings.plugin_source == "nix") or
          (settings.plugin_source == "auto" and (_G.nixInfo and _G.nixInfo.isNix))

      if is_nix then
        local nix_name = s.nix_name or s.name:match("([^/]+)$")
        local nix_path = M.resolve_nix_path(nix_name)
        if nix_path then
          lze_spec.dir = nix_path
        end
      end

      table.insert(lze_specs, lze_spec)
    end
  end

  return lze_specs
end

--- Run the selected plugin loader with transformed specs
---@param loader_type "lazy"|"lze"|"none"
---@param specs table[]
---@param settings table
function M.setup_loader(loader_type, specs, settings)
  logger.info(string.format("[Loader Adapter] Initializing loader: '%s' (Source: '%s')", loader_type, settings.plugin_source))

  if loader_type == "lazy" then
    local lazy_specs = M.to_lazy_specs(specs, settings)
    local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

    if not (vim.uv or vim.loop).fs_stat(lazy_path) and settings.plugin_source == "traditional" then
      logger.info("[Lazy Adapter] Bootstrapping lazy.nvim repository...")
      local out = vim.fn.system({
        "git", "clone", "--filter=blob:none", "--branch=stable",
        "https://github.com/folke/lazy.nvim.git", lazy_path
      })
      if vim.v.shell_error ~= 0 then
        logger.error("[Lazy Adapter] Failed to clone lazy.nvim: " .. out)
      end
    end
    vim.opt.rtp:prepend(lazy_path)

    local ok, lazy = pcall(require, "lazy")
    if ok then
      lazy.setup(lazy_specs, {
        defaults = { lazy = true },
        performance = { reset_packpath = false },
      })
    else
      logger.warn("[Lazy Adapter] lazy.nvim module not found, loading fallback configs")
      for _, s in ipairs(specs) do
        if type(s.config) == "function" then
          pcall(s.config)
        end
      end
    end

  elseif loader_type == "lze" then
    local lze_specs = M.to_lze_specs(specs, settings)
    local ok, lze = pcall(require, "lze")
    if ok then
      lze.load(lze_specs)
    else
      logger.warn("[Lze Adapter] lze module not found, executing inline plugin configs")
      for _, s in ipairs(specs) do
        if type(s.config) == "function" then
          pcall(s.config)
        end
      end
    end
  else
    logger.info("[Loader Adapter] No plugin loader active, loading inline plugin configs directly")
    for _, s in ipairs(specs) do
      if type(s.config) == "function" then
        pcall(s.config)
      end
    end
  end
end

return M
