# System Architecture & Design Philosophy

The configuration uses a **two-phase architecture**:

```
 ┌─────────────────────────────────────────────────────────┐
 │ PHASE 1: Pure Functional Configuration & Module Discovery│
 └────────────────────────────┬────────────────────────────┘
                              │
            Registers Modules & Plugin Specs into _G.Bundle
                              │
 ┌────────────────────────────▼────────────────────────────┐
 │              Table Sealing & Metatable Lock             │
 └────────────────────────────┬────────────────────────────┘
                              │
 ┌────────────────────────────▼────────────────────────────┐
 │ PHASE 2: DAG Topological Sort & Side-Effectful Execution│
 └─────────────────────────────────────────────────────────┘
```

---

## 1. The Global `_G.Bundle` Table

Initialized in `meta.lua`, `_G.Bundle` serves as the central context object during startup.

### Sub-Namespaces

| Field | Type | Description |
| :--- | :--- | :--- |
| `Bundle.meta` | `table` | System environment metadata, Nix detection, and metatable helpers |
| `Bundle.settings` | `table` | Loaded control plane settings from `lua/settings.lua` |
| `Bundle.modules` | `table` | Registry of discovered modules |
| `Bundle.specs` | `table[]` | Array of normalized plugin specs |
| `Bundle.dag` | `table` | DAG engine instance |
| `Bundle.logger` | `table` | Structured logger module |
| `Bundle.loader_adapter` | `table` | Plugin loader adapter (`lazy` / `lze`) |

---

## 2. Metatable Encapsulation & Table Locking

To guarantee that configuration tables are not mutated unpredictably or extended by typo errors, the system employs strict metatable wrappers ([`library/metatable.lua`](file:///home/addy/.config/nvim.wip/library/metatable.lua)):

### `strict_table(tbl, name, options)`
Wraps a target table with a proxy metatable:
- `__newindex`: Validates writes and catches attempts to add undeclared keys.
- Preserves iteration (`pairs`, `ipairs`, `#`) and custom string representation.

### `seal(tbl, name)`
Freezes a configuration table recursively when Phase 1 completes:
- Any attempt to add or modify a key on a sealed table throws an explicit error:
  `[SealedTable] Cannot modify frozen table 'Bundle.modules.options' (key: 'foo')`

### `unseal(tbl)`
Creates a plain, mutable copy of a table by stripping sealed metatables. Used by plugin loader adapters to pass clean specs to third-party plugin managers like Lazy.nvim without triggering metatable lock errors.
