# Persistent State Engine & 3-Tier Data Architecture

The configuration implements a **3-Tier Data Architecture** with an **NvChad-Style Cross-Session Persistent State Engine** stored in `stdpath("state")`.

---

## 1. The 3-Tier Data Architecture

To achieve 100% decoupling and plug-and-play swappability, the configuration cleanly separates **User Intent** (static preferences) from **Runtime State** (dynamic live memory):

```
┌─────────────────────────────────────────────────────────────┐
│  TIER 1: Control Plane (lua/settings.lua)                   │
│  User Intent & Flags: colorscheme = "catppuccin", etc.       │
└──────────────────────────────┬──────────────────────────────┘
                               │ Ingested at startup via Bundle:init()
                               ▼
┌─────────────────────────────────────────────────────────────┐
│  TIER 2: Core Hub (_G.Bundle)                               │
│  • Bundle.settings ──► Holds user preferences from Tier 1    │
│  • Bundle.defaults ──► Holds default fallback palettes      │
│  • Bundle.state    ──► Holds live dynamic state & state JSON│
└──────────────────────────────┬──────────────────────────────┘
                               │ Read & Written by DAG Nodes
                               ▼
┌─────────────────────────────────────────────────────────────┐
│  TIER 3: Atomic Modules (lua/modules/...)                  │
│  • Modules read preferences from Bundle.settings / state     │
│  • Modules publish live updates to Bundle.state             │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. NvChad-Style Cross-Session State Engine

### Problem Solved
In NixOS / Nix wrapper environments, files in `/nix/store/...` are read-only. Editing code or configuration files at runtime requires a full system or flake rebuild.

### Solution
Runtime UI modifications (such as changing colorschemes, toggling transparency, or toggling line numbers) are automatically persisted to disk in `stdpath("state")`:

```
~/.local/state/nvim/bundle_state.json
```

```json
{
  "colorscheme": "catppuccin-mocha",
  "transparent": true,
  "number": true,
  "relativenumber": true
}
```

---

## 3. Boot Lifecycle & Synchronization

1. **Module Discovery**:
   - `lua/meta.lua` initializes `_G.Bundle` and sets default fallbacks in `Bundle.defaults`.

2. **State Hydration (`Bundle:load_state()`)**:
   - `Bundle:init()` checks if `~/.local/state/nvim/bundle_state.json` exists.
   - **If file exists**: Decodes JSON into `Bundle.state`, overriding defaults with saved cross-session choices.
   - **If file missing**: Hydrates `Bundle.state` from `Bundle.defaults` / `Bundle.settings` and immediately saves `bundle_state.json`.

3. **Runtime Persist (`Bundle:save_state()`)**:
   - Running `:colorscheme <name>`, `:ToggleTransparency`, `<leader>n` (toggle line numbers), or `<leader>rn` (toggle relative numbers) updates `Bundle.state` and automatically saves `bundle_state.json` to disk.
