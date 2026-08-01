# 01 System Architecture: Topological DAG & Data Engine

This document provides a technical deep-dive into the core execution engine of the Neovim configuration: the **Directed Acyclic Graph (DAG) Execution Engine**, the **Decoupled 3-Tier Data Architecture**, and **Metatable Table Sealing**.

---

## 1. Functional DAG Execution Engine

### 🔍 Architectural Need
Traditional Neovim configurations rely on arbitrary `require()` order or implicit plugin loading order. This leads to subtle ordering bugs (e.g., keymaps referencing options before options are set, or colorschemes overriding highlights before plugins load).

### 📐 Technical Architecture
The engine structures configuration modules as nodes in a Directed Acyclic Graph (DAG), resolved via **Kahn's Topological Sorting Algorithm** with Depth-First Search (DFS) cycle protection.

#### Phase Priority Continuum
Modules register with specific phase priorities:

| Phase Enum | Numeric Priority | Description |
| :--- | :--- | :--- |
| **`SETUP`** | `10` | Bootstrap framework, logger, persistent state initialization |
| **`OPTIONS`** | `20` | Vim global & buffer options (`o.cmdheight`, `opt.number`, `opt.signcolumn`) |
| **`KEYMAPS`** | `30` | Centralized keymap registry & essential bindings |
| **`AUTOCMDS`** | `40` | Global autocommands & FileType triggers |
| **`LOADER`** | `50` | Declarative plugin loader adapter (`lazy.nvim` vs `lze`) |
| **`PLUGINS`** | `60` | Dynamic plugin specifications (LSP, Treesitter, Formatter, Linter, DAP) |
| **`POST`** | `70` | Post-initialization UI hooks, transparency engine, statusline attachment |

#### Kahn's Algorithm Implementation ([`lua/library/dag.lua`](file:///home/addy/.config/nvim/lua/library/dag.lua))
```lua
function M.topological_sort(modules)
  local in_degree = {}
  local graph = {}
  local sorted = {}

  -- Compute in-degrees and build adjacency lists
  for id, mod in pairs(modules) do
    in_degree[id] = in_degree[id] or 0
    graph[id] = graph[id] or {}
    for _, dep in ipairs(mod.deps or {}) do
      graph[dep] = graph[dep] or {}
      table.insert(graph[dep], id)
      in_degree[id] = (in_degree[id] or 0) + 1
    end
  end

  -- Queue nodes with in-degree 0, sorted by phase priority
  local queue = {}
  for id, deg in pairs(in_degree) do
    if deg == 0 then table.insert(queue, modules[id]) end
  end

  table.sort(queue, function(a, b) return a.phase < b.phase end)

  while #queue > 0 do
    local curr = table.remove(queue, 1)
    table.insert(sorted, curr)

    for _, neighbor in ipairs(graph[curr.id] or {}) do
      in_degree[neighbor] = in_degree[neighbor] - 1
      if in_degree[neighbor] == 0 then
        table.insert(queue, modules[neighbor])
        table.sort(queue, function(a, b) return a.phase < b.phase end)
      end
    end
  end

  -- Cycle Guard
  if #sorted < vim.tbl_count(modules) then
    error("[DAG Error] Circular dependency detected in configuration graph!")
  end

  return sorted
end
```

---

## 2. Decoupled 3-Tier Data Architecture & State Engine

The configuration separates static settings, immutable defaults, and cross-session runtime state into three decoupled tiers in [`lua/meta.lua`](file:///home/addy/.config/nvim/lua/meta.lua):

```
┌─────────────────────────────────────────────────────────────┐
│                      Control Plane                          │
│                                                             │
│   Bundle.settings  ◄── Ingested from lua/settings.lua       │
│   Bundle.defaults  ◄── Sealed Immutable Fallbacks           │
│   Bundle.state     ◄── Live Runtime Persistence Engine      │
│                                                             │
└──────────────────────────────┬──────────────────────────────┘
                               │
            ┌──────────────────┴──────────────────┐
            │ Persistent State JSON Serialization │
            │ ~/.local/state/nvim/bundle_state.json│
            └─────────────────────────────────────┘
```

### 3-Tier Data Layers
1. **`Bundle.settings`**: Static feature flags ingested from [`lua/settings.lua`](file:///home/addy/.config/nvim/lua/settings.lua) (`isolation`, `loader`, `auto_attach_lsp`, `auto_attach_formatter`).
2. **`Bundle.defaults`**: Immutable fallback table. Read-only defaults for line numbers, colorschemes, transparency, and toggles.
3. **`Bundle.state`**: Live runtime state. Automatically serialized to JSON at `~/.local/state/nvim/bundle_state.json` whenever toggles change (`<leader>n`, `<leader>rn`, `:ToggleTransparency`).

### Isolation Modes
Configured via `settings.isolation`:
- **`strict`**: Zero disk persistence. State is ephemeral; undo files live in `/tmp/neovim/undo`.
- **`tmp`**: Ephemeral persistence. `bundle_state.json` and undo files stored in `/tmp/neovim/`.
- **`flexible` (Default)**: Permanent state persistence. State saved to `~/.local/state/nvim/bundle_state.json` and undo files saved to `~/.local/state/nvim/undo`.

---

## 3. Metatable Encapsulation & Table Sealing

To prevent accidental global variable pollution and typos in configuration tables, [`lua/library/metatable.lua`](file:///home/addy/.config/nvim/lua/library/metatable.lua) implements strict table proxy sealing:

```lua
local M = {}

--- Wrap a table in a protective proxy metatable that errors on invalid reads/writes
function M.seal(target, name)
  local proxy = {}
  local mt = {
    __index = function(_, key)
      if target[key] ~= nil then return target[key] end
      error(string.format("[Strict Metatable Guard] Attempted to read uninitialized key '%s' on table '%s'", tostring(key), name), 2)
    end,
    __newindex = function(_, key, value)
      if not rawget(target, "__unsealed") then
        error(string.format("[Strict Metatable Guard] Attempted to mutate sealed key '%s' on table '%s'", tostring(key), name), 2)
      end
      rawset(target, key, value)
    end,
  }
  return setmetatable(proxy, mt)
end

--- Temporarily unseal a table for safe plugin spec mutation
function M.unseal(target, fn)
  rawset(target, "__unsealed", true)
  local ok, err = pcall(fn)
  rawset(target, "__unsealed", nil)
  if not ok then error(err) end
end

return M
```

#### Why Table Sealing is Critical:
- Prevents silent global mutations (`vim.g.my_typo_var`).
- `unseal()` bridge allows `lazy.nvim` and `lze` to safely mutate plugin spec tables during registration without breaking configuration immutability.
