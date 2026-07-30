# Deep Code Review: Modular DAG Neovim Configuration

Audit date: 2026-07-30

**Scope**: All files under `lua/`, `docs/`, `tests/`, `init.lua`, `settings.lua`, `module.nix`, `flake.nix`

---

## Index

- [Category A: Architecture Policy Violations](#category-a-architecture-policy-violations)
- [Category B: Implementation Bugs & Gaps](#category-b-implementation-bugs--gaps)
- [Category C: Code Quality Issues](#category-c-code-quality-issues)
- [Category D: Documentation vs Implementation Drift](#category-d-documentation-vs-implementation-drift)
- [Category E: Minor Issues & Nitpicks](#category-e-minor-issues--nitpicks)

---

## Category A: Architecture Policy Violations

### A1. Undeclared `Bundle.bridge` — phantom shared namespace

| File | Line | Code |
|------|------|------|
| `lua/modules/kitty.lua` | 40-41 | `_G.Bundle.bridge.set_terminal_padding = set_kitty_padding` |
| `lua/modules/plugins/formatter.lua` | 74-75 | `_G.Bundle.bridge.format = M.format_buffer` |
| `lua/modules/plugins/linter.lua` | 39-40 | `_G.Bundle.bridge.lint = M.lint_buffer` |

**Problem**: Three modules write to `Bundle.bridge` but **no code anywhere in the repo creates it**. The `Bundle` table (`lua/meta.lua`) has no `bridge` key. Every write is gated by `if _G.Bundle and _G.Bundle.bridge then`, which means all three silently **no-op** at runtime. This is dead code masked as decoupling.

The `bridge` abstraction was clearly intended as an inter-module callback registry, but it has no producer, no initializer, no schema, no documentation, and no consumers.

**Fix**: Either initialize `Bundle.bridge = {}` in `meta.lua` and document the contract, or remove the pattern and use direct function references.

---

### A2. `Bundle:notify()` hard-couples core framework to `fidget` plugin

`lua/meta.lua:145-157`:

```lua
function Bundle:notify(msg, level, opts)
  local ok_fidget, fidget = pcall(require, "fidget")
  if ok_fidget and type(fidget.notify) == "function" then
    pcall(fidget.notify, msg, level, opts or {})
  else
    vim.notify(msg, level, opts or {})
  end
end
```

**Problem**: The **core framework layer** (`meta.lua`) does a `pcall(require, "fidget")` — a direct require of a plugin module by string name. This violates the "no direct module-to-module require" policy at the most fundamental layer. If `fidget` is disabled in settings, this still attempts to load it. If `fidget`'s API changes, this silently fails.

Additionally, `direnv.lua:39` calls `_G.Bundle:notify()` which routes through this fidget-coupling, meaning the notification path is not decoupled at all.

**Fix**: Use a registration pattern — modules register their `notify` function with Bundle, and `Bundle:notify()` delegates to the registered handler. No require-by-name in the framework.

---

### A3. Phantom `Bundle.defaults.render_markdown` — contract with no provider

`lua/modules/plugins/render_markdown.lua:7`:

```lua
local defaults = _G.Bundle and _G.Bundle.defaults and _G.Bundle.defaults.render_markdown or {}
```

**Problem**: `Bundle.defaults` is initialized in `lua/meta.lua:49-54` with only four keys: `colorscheme`, `transparent`, `number`, `relativenumber`. The key `render_markdown` is **never set anywhere** in the entire codebase. Every highlight color in the `apply_markdown_theme()` function silently falls through to hardcoded fallback values, with no warning.

This is a designed extension point (documented in the comment on line 2) that was started but never wired up. Any module wishing to contribute markdown highlight palettes has no documented place to do so.

**Fix**: Either populate `Bundle.defaults.render_markdown` with a palette struct, or remove the `Bundle.defaults` indirection and use local constants.

---

### A4. `render_markdown` declares DAG `deps` on another plugin module

`lua/modules/plugins/render_markdown.lua:38`:

```lua
deps = { "options", "treesitter" },
```

**Problem**: Both `render_markdown` and `treesitter` execute at Phase 60 (`PLUGINS`). Declaring `"treesitter"` as a dependency:
  - Creates an implicit ordering constraint between two co-phase plugin modules
  - If `treesitter` is disabled in `settings.lua`, the DAG node won't exist, producing a warning/error
  - If the treesitter plugin spec fails, render_markdown is blocked

Plugin modules should not hardcode dependencies on other plugin modules. The architecture explicitly states modules should communicate only through `Bundle.settings`/`Bundle.state`.

**Fix**: Remove the `treesitter` dep. If render-markdown requires treesitter parsers, add it as a plugin `deps` entry in the spec table instead, or handle gracefully at runtime.

---

### A5. Unstructured `Bundle.state` — ungoverned flat key namespace

| File | Keys Written |
|------|-------------|
| `lua/modules/options.lua` | `Bundle.state.number`, `Bundle.state.relativenumber` |
| `lua/modules/plugins/colorscheme.lua` | `Bundle.state.colorscheme` |
| `lua/modules/plugins/transparency.lua` | `Bundle.state.transparent` |

**Problem**: The architecture documents a "3-tier data model" but the state tier has:
  - No key registry or schema
  - No type validation on read or write
  - No migration path for key changes
  - No namespacing to prevent conflicts

Any module can write `Bundle.state.anything` and collide with another module. The `Bundle:save_state()` function (`meta.lua:123-142`) explicitly enumerates only four keys in its serialization, so any other keys written to `Bundle.state` are silently dropped on persist — meaning they exist only in the current session and are lost on restart.

**Fix**: Define a typed schema for `Bundle.state` and enforce it on write. Consider scoping state by module id (e.g., `Bundle.state.modules.colorscheme = {...}`).

---

### A6. `keymaps.lua` mutates settings consumed by unrelated modules

`lua/modules/keymaps.lua:50-77`:

| Command | Setting Mutated | Consumed By |
|---------|----------------|-------------|
| `:ToggleFormatOnSave` | `Bundle.settings.format_on_save` | `formatter.lua:88-89` |
| `:ToggleFormatter` | `Bundle.settings.auto_attach_formatter` | (documented, not yet implemented) |
| `:ToggleLinter` | `Bundle.settings.auto_attach_linter` | (documented, not yet implemented) |
| `:ToggleDAP` | `Bundle.settings.auto_attach_dap` | (documented, not yet implemented) |

**Problem**: The keymaps module knows about setting names that semantically belong to `formatter`, `linter`, and `dap` modules. This is a cross-concern coupling. If a setting name changes in `settings.lua`, the keymaps module must be updated too. The Toggle commands should be defined by the owning module or registered via a callback system.

Additionally, the last three settings (`auto_attach_formatter`, `auto_attach_linter`, `auto_attach_dap`) are **declared** in settings.lua and **toggled** in keymaps.lua but **never consumed** by any module — they are dead code.

**Fix**: Have each module register its own toggle commands, or move toggle logic into a settings-controller module. Remove unused settings until they have consumers.

---

## Category B: Implementation Bugs & Gaps

### B1. `strict_mode` setting declared but never consumed

`lua/settings.lua:16`, `init.lua:31`:

```lua
M.strict_mode = true
```

**Problem**: The `strict_mode` setting is declared as a default and loaded into `Bundle.settings`, but **no code ever reads it**. The `meta.seal` and `meta.strict_table` functions (in `library/metatable.lua`) exist and are exposed via `Bundle.meta.seal`, but neither is ever called. No table sealing happens anywhere. A `strict_mode = true` setting has zero effect.

**Fix**: In `Bundle:init()` or `Bundle:execute()`, check `settings.strict_mode` and call `meta.seal()` on `Bundle.modules`, `Bundle.settings`, and/or `Bundle.defaults` to enforce immutability.

---

### B2. `isolation` mode not applied to `undodir`

`lua/modules/options.lua:56-61`:

```lua
local undodir = "/tmp/neovim/"
```

**Problem**: `lua/meta.lua:63-81` implements three isolation modes (`strict`, `tmp`, `flexible`) that control state file location. But `options.lua` always hardcodes `/tmp/neovim/` for `undodir` regardless of the setting. According to `progress.md`, `flexible` mode should use `~/.local/state/nvim/undo`.

Additionally, `options.lua` uses `directory` for swap and backup (which are disabled anyway), but hardcodes `/tmp/neovim/` while `Bundle:get_state_filepath()` would use different paths depending on isolation mode. These paths are inconsistent.

**Fix**: Either expose `Bundle:get_state_dir()` on the Bundle object and consume it in `options.lua`, or remove the isolation mode abstraction if it's not fully implemented.

---

### B3. Key conflict: `<leader>e` mapped twice

| File | Line | Mapping |
|------|------|---------|
| `lua/modules/keymaps.lua` | 39 | `<leader>e` → `open_floating_diagnostic` |
| `lua/modules/plugins/file_explorer.lua` | 18 | `<leader>e` → `NvimTreeFocus` |

**Problem**: `keymaps.lua` registers during Phase 30 (`KEYMAPS`). `file_explorer.lua` registers spec `keys` during Phase 60 (`PLUGINS`) via the loader adapter. Depending on how Lazy.nvim handles in-spec `keys`, one mapping silently overwrites the other. The user expects `<leader>e` to open LSP diagnostics (per keymaps.lua) but will get NvimTree focus instead (or vice versa).

**Fix**: Remove the `<leader>e` mapping from one of the two files. Addressed by picking unique keybindings or documenting the override.

---

### B4. Prefix collision: `<leader>c` shadows `<leader>cd`

| File | Line | Mapping |
|------|------|---------|
| `lua/modules/plugins/telescope.lua` | 21 | `<leader>c` → `Telescope commands` (immediate) |
| `lua/modules/keymaps.lua` | 38 | `<leader>cd` → `open_floating_diagnostic` |

**Problem**: `<leader>c` in telescope.lua is an immediate mapping (`<cmd>Telescope commands<cr>`), not a prefix group. Pressing `<leader>c` fires Telescope commands immediately, making `<leader>cd` unreachable — the `d` is never read because the action fires on `c`.

**Fix**: Change telescope's `<leader>c` to `<leader>cm` (or similar) to avoid eating the `c` prefix namespace.

---

### B5. `linter.lua` stub — `lint_buffer` never actually lints

`lua/modules/plugins/linter.lua:18-29`:

```lua
function M.lint_buffer(bufnr)
  ...
  for _, lnt in ipairs(candidates) do
    if vim.fn.executable(lnt.bin) == 1 then
      logger.debug(...)  -- logs but does nothing
    end
  end
end
```

**Problem**: The `lint_buffer` function iterates discovered linters and logs debugging info, but **never executes any linter** and **never populates `vim.diagnostic`**. It's a no-op. The autocommand at line 48-52 triggers on `BufReadPost` and `BufWritePost` calling this function, producing debug log spam with zero user-visible effect.

**Fix**: Either implement actual linter execution (parse output, set vim.diagnostic), or remove the module and its autocommand.

---

## Category C: Code Quality Issues

### C1. Indentation inconsistency

| Files | Indent Width |
|-------|-------------|
| All files in `lua/modules/` except `telescope.lua` and `lualine.lua` | **2 spaces** |
| `lua/modules/plugins/telescope.lua` | **4 spaces** |
| `lua/modules/plugins/lualine.lua` | **4 spaces** |

Two files use 4-space indentation while the rest of the codebase uses 2-space. This is a style inconsistency.

---

### C2. `lualine.lua` duplicates formatter/linter tables

`lua/modules/plugins/lualine.lua:19-31` defines a formatter list (by filetype → binaries) that is an **exact duplicate** of the one in `lua/modules/plugins/formatter.lua:10-22`. Similarly, lines 41-47 duplicate the linter list from `linter.lua:9-15`.

**Problem**: Any change to formatter/linter candidates must be made in **three** places (formatter.lua, linter.lua, lualine.lua). These will inevitably drift.

**Fix**: Share the candidate tables through a common source — either `Bundle` state or a shared `library/` utility.

---

### C3. `kitty.lua` uses blocking `vim.fn.system()`

`lua/modules/kitty.lua:24`:

```lua
local out = vim.fn.system(cmd)
```

**Problem**: This runs synchronously on `VimEnter`/`UIEnter`/`VimLeavePre`, blocking the UI event loop. For kitty remote control operations that involve socket communication, even a minor delay is perceptible. The `VimLeavePre` handler is especially risky since Neovim must finish teardown promptly.

**Fix**: Use `vim.system()` (async) with a callback, and accept that padding may apply a frame or two after startup.

---

### C4. `formatter.lua` repetitive `elseif` chain

`lua/modules/plugins/formatter.lua:35-55` has a 9-branch `elseif` chain:

```lua
if fmt.bin == "stylua" then
  ...
elseif fmt.bin == "nixfmt" or fmt.bin == "alejandra" or ... then
  ...
elseif ...
```

Every branch performs **identical logic** — pipe buffer content through stdin, read stdout, replace buffer lines. The only variation is the binary name. This should be a single generic path.

**Fix**: Remove the `elseif` chain. Read input, run `vim.fn.system(fmt.bin, input)`, replace buffer lines. Handle stylua's `-` argument syntax as a special case only if needed.

---

### C5. `blink_cmp.lua` builds twice

`lua/modules/plugins/blink_cmp.lua:17-18` (spec `build`):

```lua
build = function()
  require("blink.cmp").build():pwait()
end,
```

...and then again in `config` (lines 42-46):

```lua
if not pcall(require, "blink.lib") then
  ...
  pcall(function() blink.build():pwait() end)
end
```

**Problem**: The `build` step runs during plugin installation via the loader. The `config` fallback runs the same build step again if the native lib is missing at runtime. Either the build step already succeeded (making the config fallback redundant) or it failed (and the fallback will likely fail identically).

**Fix**: Remove the config-time fallback, or remove the spec `build` and rely only on the lazy fallback.

---

### C6. `telescope.lua` eagerly loaded with `lazy = false`

`lua/modules/plugins/telescope.lua:14`:

```lua
lazy = false,
```

**Problem**: Telescope is a heavy plugin with multiple dependencies (plenary.nvim, prompt buffers, pickers, previewers). Setting `lazy = false` forces it to load at startup even though its keybindings (`<leader>ff`, `<leader>fw`, etc.) could lazy-load it on first use. This contradicts the architecture's "lazy by default" philosophy (`init.lua` configures `defaults = { lazy = true }`).

**Fix**: Make telescope lazy-loaded via its `keys` entries (Lazy.nvim can handle this automatically when `keys` are present).

---

## Category D: Documentation vs Implementation Drift

### D1. `docs/control_plane.md` example is incomplete

The control_plane.md shows an example `settings.lua` with only 7 modules:
```
options = true, keymaps = true, autocmds = true,
colorscheme = true, treesitter = true, lsp = true, telescope = true,
```

But the actual `lua/settings.lua:29-48` has **18 entries**. The documentation has drifted far from reality.

---

### D2. `docs/architecture.md` directory tree omits `kitty.lua`

The architecture.md directory tree lists:
```
lua/modules/
├── init.lua
├── options.lua
├── keymaps.lua
├── autocmds.lua
└── plugins/    (...)
```

But `lua/modules/kitty.lua` exists and is not shown.

---

### D3. `progress.md` says `isolation` should be in `settings.lua` — it isn't

`progress.md:44` says: "Configure `isolation` setting in `lua/settings.lua` and `lua/meta.lua`."

The `meta.lua` implements the setting (line 65: `self.settings.isolation or "flexible"`), but `lua/settings.lua` does **not** declare `M.isolation = "flexible"`. The setting only works if another module writes it, or defaults to `"flexible"` silently. It should be an explicit option in the control plane.

---

### D4. `docs/persistent_state.md` mentions `Bundle.defaults` for render_markdown palettes

The document says "`Bundle.defaults` holds default fallback palettes" and the architecture diagram shows `Bundle.defaults` as a sealed immutable fallback. But the only code that reads from `Bundle.defaults.*` besides the core four keys is `render_markdown.lua`, and that key is never set. The `Bundle.defaults` table is never sealed either (see B1).

---

## Category E: Minor Issues & Nitpicks

### E1. Plugin list drifts between `module.nix` and `flake.nix`

The `module.nix` at the repo root lists plugins for the kannix (lazy-based) build path, while `wrapper_modules/module.nix` lists plugins for the lze-based (wrapper) build path. Both reference `blink-cmp`, `fidget-nvim`, `lualine-nvim`, etc. but the sets **differ** — `wrapper_modules/module.nix` includes `snacks-nvim`, `gitsigns-nvim`, `vim-sleuth`, `nvim-surround`, `vim-startuptime` which don't appear in the root `module.nix` or in `lua/modules/plugins/`.

Conversely, the root `module.nix` includes `render-markdown-nvim`, `telescope-nvim`, `nvim-tree-lua` which don't appear in `wrapper_modules/module.nix`.

If these are two separate build paths for the same config, the plugin divergence means features work in one build but not the other.

---

### E2. `result/` directory is committed to git

The `result/` directory contains Nix build outputs (symlinks into `/nix/store`). These are build artifacts and should be in `.gitignore`.

---

### E3. `tree-sitter` grammar file for Kitty

`lua/modules/kitty.lua` — the file is incongruously named. A file named `kitty.lua` in `lua/modules/` is auto-discovered and treated as a configuration module, not a plugin module. It doesn't register any plugin specs. This works but is confusing when scanning the directory.

---

### E4. `fidget.lua` declares `deps = { "lsp" }`

`lua/modules/plugins/fidget.lua:7`:

```lua
deps = { "options", "lsp" },
```

Fidget.nvim is a UI notification library. It has no functional dependency on the LSP module. If LSP is disabled, fidget is never loaded (DAG order will fail). This is an unnecessary coupling.

---

### E5. `mason.lua` declares `deps = { "lsp" }`

`lua/modules/plugins/mason.lua:9`:

```lua
deps = { "options", "lsp" },
```

Similarly, Mason does not require the lsp module. If LSP is disabled, Mason won't load even though it's a standalone plugin manager.

---

### E6. `options.lua` uses global `state` variable instead of reading from Bundle at execution time

`lua/modules/options.lua:14`:

```lua
local state = _G.Bundle and _G.Bundle.state or {}
```

This is evaluated at **module load time** (Phase 1 — pure discovery), not at **execution time** (Phase 2 — side effects). If `Bundle.state` changes between module load and module exec (e.g., via another module's init), the stale local `state` is still used. All other modules access `_G.Bundle.state` inside their `exec()` function, which is correct.

---

### E7. `direnv.lua` calls `sync_direnv()` twice on startup

`lua/modules/plugins/direnv.lua`:

- Line 62: Inside the spec `config` function (runs via loader)
- Line 76: Inside the module `exec` function (runs via DAG)

Both trigger a `direnv export json` subprocess on startup. The `VimEnter` autocommand (line 65) fires the same function again. On first boot, `direnv` may be called 3 times, with 2 of them nearly instantaneous duplicates.

---

### E8. `kitty.lua` Phase 10 dependency on Phase 20 module

`lua/modules/kitty.lua:36-37`:

```lua
phase = dag_lib.Phases.SETUP,   -- Phase 10
deps = { "options" },            -- options.lua -> Phase 20
```

A Phase 10 module depends on a Phase 20 module. The DAG handles this by topological sort across phases (options runs first anyway due to phase ordering), but it's logically inverted — kitty wants core options set first. It should either also run at Phase 20 or remove the dep.

---

### E9. No test coverage for `loader_adapter.lua` Nix path resolution

`tests/run_tests.lua` tests `dag.lua`, `metatable.lua`, and `loader_adapter.lua` spec transformation, but the Nix store path resolution (`resolve_nix_path()`) is untested. This is a critical path for NixOS users.

---

### Summary

| Severity | Count |
|----------|-------|
| Architecture Violations (A1-A6) | 6 |
| Bugs & Gaps (B1-B5) | 5 |
| Code Quality (C1-C6) | 6 |
| Doc Drift (D1-D4) | 4 |
| Minor Issues (E1-E9) | 9 |
| **Total** | **30** |
