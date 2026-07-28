# Diagnostics, Logging & Debugging

The system provides structured logging and diagnostic Neovim commands to trace execution, debug errors, and measure performance.

---

## 1. Diagnostic User Commands

Run these commands inside Neovim at any time:

### `:DagStatus`
Prints a summary of the DAG execution stats:
```
DAG Status: 8 executed, 0 failed in 24.15ms
```

### `:DagLog`
Opens a new scratch buffer containing the complete, chronologically ordered execution log:
```
[06:31:14] [INFO] [Bundle Init] Initializing configuration bundle...
[06:31:14] [INFO] [Module Registry] Dynamically scanning lua/modules/ directory...
[06:31:14] [INFO] [Module Registry] Successfully registered 7 modules dynamically
[06:31:14] [INFO] [Bundle DAG] Building execution graph...
[06:31:14] [INFO] [Bundle DAG] Graph constructed with 8 nodes
[06:31:14] [INFO] [Bundle] Configuration tables sealed with metatable locks
[06:31:14] [INFO] [Bundle Execution] Commencing side-effect execution phase...
[06:31:14] [INFO] [DAG Execution] Starting execution of 8 nodes
[06:31:14] [INFO] [DAG Success] 'options' completed in 0.12ms
[06:31:14] [INFO] [DAG Success] 'keymaps' completed in 0.18ms
[06:31:14] [INFO] [DAG Success] 'autocmds' completed in 0.02ms
[06:31:14] [INFO] [Loader Adapter] Initializing loader: 'lazy' (Source: 'auto')
[06:31:14] [INFO] [DAG Success] 'system.plugin_loader' completed in 20.70ms
[06:31:14] [INFO] [DAG Success] 'colorscheme' completed in 2.65ms
[06:31:14] [INFO] [DAG Success] 'lsp' completed in 0.00ms
[06:31:14] [INFO] [DAG Success] 'telescope' completed in 0.00ms
[06:31:14] [INFO] [DAG Success] 'treesitter' completed in 0.00ms
[06:31:14] [INFO] [DAG Execution Summary] 8 executed, 0 failed in 23.91ms
```

### `:BundleInfo`
Displays system context details:
```
Loader: lazy
Plugin Source: auto
Is Nix: false
Registered Modules: 7
Registered Specs: 4
```

---

## 2. File Log Location

Logs are continuously appended to Neovim's state directory at:
```
stdpath("state") .. "/dag_nvim.log"
```

You can view live log entries in a terminal with:
```bash
tail -f ~/.local/state/nvim/dag_nvim.log
```

---

## 3. Custom Logging in Modules

You can use the built-in logger (`Bundle.logger` or `require("library.logger")`) inside your modules or plugins:

```lua
local logger = require("library.logger")

logger.debug("Starting custom setup...")
logger.info("Custom module initialized successfully")
logger.warn("Optional binary missing from PATH")
logger.error("Failed to load component", { err = err_msg })
```
