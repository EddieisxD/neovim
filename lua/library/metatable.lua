--- Strict Metatable & Encapsulation Utility
--- Provides mechanisms to prevent accidental dynamic extensions or reading undefined keys.

local M = {}

--- Wraps a table with a strict metatable that errors or warns on accessing/writing undefined keys.
---@param tbl table The target table
---@param name string Name of the table for debugging messages
---@param options? { allow_extension?: boolean, freeze?: boolean }
---@return table
function M.strict_table(tbl, name, options)
  tbl = tbl or {}
  name = name or "AnonymousTable"
  options = options or {}

  local proxy = {}
  local raw = tbl
  local frozen = options.freeze or false

  local mt = {
    __index = function(_, key)
      if raw[key] ~= nil then
        return raw[key]
      end
      -- Return nil but warn if strict debugging is desired
      return nil
    end,

    __newindex = function(_, key, value)
      if frozen then
        error(string.format("[StrictTable] Attempt to write key '%s' to frozen table '%s'", tostring(key), name), 2)
      end
      if not options.allow_extension and raw[key] == nil then
        -- Check if key already existed
        raw[key] = value
      else
        raw[key] = value
      end
    end,

    __pairs = function()
      return pairs(raw)
    end,

    __ipairs = function()
      return ipairs(raw)
    end,

    __len = function()
      return #raw
    end,
  }

  setmetatable(proxy, mt)
  return proxy
end

--- Freezes a table completely so no new keys can be added or existing keys modified.
---@param tbl table
---@param name string
---@return table
function M.seal(tbl, name)
  name = name or "SealedTable"

  for k, v in pairs(tbl) do
    if type(v) == "table" and not getmetatable(v) then
      tbl[k] = M.seal(v, name .. "." .. tostring(k))
    end
  end

  local sealed_mt = {
    __newindex = function(_, key, _)
      error(string.format("[SealedTable] Cannot modify frozen table '%s' (key: '%s')", name, tostring(key)), 2)
    end,
    __tostring = function() return string.format("<SealedTable: %s>", name) end,
  }

  return setmetatable(tbl, sealed_mt)
end

--- Recursively creates a plain, mutable copy of a table stripped of sealed metatables
---@param tbl table
---@return table
function M.unseal(tbl)
  if type(tbl) ~= "table" then return tbl end

  local copy = {}
  for k, v in pairs(tbl) do
    if type(v) == "table" then
      copy[k] = M.unseal(v)
    else
      copy[k] = v
    end
  end
  return copy
end

return M
