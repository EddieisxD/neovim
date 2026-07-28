# Modular DAG Neovim Architecture Documentation

Welcome to the documentation for the **Modular DAG-based Neovim Configuration Engine**. This system provides a pure functional configuration pipeline, strict metatable encapsulation, loader-agnostic plugin specifications (`lazy.nvim` & `lze`), Nix vs. Traditional plugin store resolution, and a Directed Acyclic Graph (DAG) side-effect execution engine.

---

## 📚 Documentation Index

1. [**System Architecture**](architecture.md)
   - Overview of `_G.Bundle`
   - Pure functional configuration vs. side-effectful execution
   - Strict metatable encapsulation (`strict_table`, `seal`, `unseal`)

2. [**DAG Execution Engine**](dag_engine.md)
   - Execution phases (`SETUP`, `OPTIONS`, `KEYMAPS`, `AUTOCMDS`, `LOADER`, `PLUGINS`, `POST`)
   - Topological sorting algorithm
   - Dependency graph resolution & cycle detection

3. [**Control Plane & Settings**](control_plane.md)
   - Config control plane (`lua/settings.lua`)
   - Loader selection (`lazy` vs. `lze`)
   - Download source selection (`nix` vs. `traditional` vs. `auto`)
   - Module toggles and strict mode

4. [**Loader Adapters & Plugin Specs**](loader_adapters.md)
   - Universal plugin spec schema
   - Pre-load (`before`/`init`), setup (`config`/`load`), post-load (`after`/`post`) hooks
   - Keybindings integration
   - Nix store path auto-resolution

5. [**Module Authoring Guide**](module_authoring.md)
   - Creating new modules in `lua/modules/`
   - Zero-manifest dynamic directory discovery (`lua/modules/init.lua`)
   - Complete real-world module examples

6. [**Diagnostics & Logging**](diagnostics.md)
   - Structured logger (`library/logger.lua`)
   - Diagnostic commands (`:DagStatus`, `:DagLog`, `:BundleInfo`)
   - Debugging errors and timing metrics

---

## ⚡ Quick Start

### Directory Structure Overview
```
.
├── init.lua                   # Main entry point
├── meta.lua                   # Global Bundle initializer & path environment setup
├── docs/                      # Complete system documentation
├── library/
│   ├── metatable.lua          # Encapsulation & strict table guards
│   ├── logger.lua             # Structured event & timing logger
│   ├── dag.lua                # DAG graph solver & topological sorter
│   └── loader_adapter.lua     # Universal plugin spec converter for Lazy / Lze
└── lua/
    ├── settings.lua           # Control plane settings
    └── modules/
        ├── init.lua           # Dynamic file scanner & module auto-loader
        ├── options.lua        # Core Vim options
        ├── keymaps.lua        # Core keymaps
        ├── autocmds.lua       # Core autocommands
        └── plugins/           # Plugin modules (colorscheme, treesitter, lsp, telescope)
```

### Running Diagnostic Commands inside Neovim

- `:DagStatus`: View total executed vs failed DAG nodes and execution time.
- `:DagLog`: Open an interactive log buffer showing node execution timings and debug events.
- `:BundleInfo`: Display current loader choice, plugin source, Nix detection status, and registered module/spec counts.
