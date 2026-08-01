# 02 Nix Wrapper & Flake Architecture: Dual Loader & NixOS Integration

This document details how the Neovim configuration integrates natively with Nix, NixOS system flakes, and traditional non-Nix environments using the **Dual-Mode Loader Adapter** and **`wrapperModules`**.

---

## 1. Pure Nix & Traditional Dual-Mode Loader Adapter

### Architectural Concept
In traditional Neovim configurations, plugin specs are written specifically for a single plugin manager (e.g. `lazy.nvim` or `packer.nvim`). Under NixOS, using imperative Git downloaders like `lazy.nvim` breaks Nix reproducability. Conversely, locking a config exclusively to Nix makes it unusable on non-Nix Linux or macOS systems.

Our architecture uses a **Universal Plugin Specification Translator** ([`lua/library/loader_adapter.lua`](file:///home/addy/.config/nvim/lua/library/loader_adapter.lua)):

```
                       Universal Plugin Spec Table
                                   │
              ┌────────────────────┴────────────────────┐
              ▼                                         ▼
      loader = "lazy"                           loader = "lze"
    (Traditional Git)                       (Nix Wrapper Modules)
              │                                         │
    Translates to Lazy.nvim                   Translates to lze
    Git repository specs                      /nix/store plugin derivations
```

### Universal Spec Format
Every plugin in `lua/modules/plugins/` uses a universal spec table:

```lua
return {
  id = "telescope",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options", "keymaps" },
  specs = {
    {
      name = "nvim-telescope/telescope.nvim", -- Git repo name for lazy.nvim
      id = "telescope",                       -- Identifier for lze
      nix_name = "telescope-nvim",            -- Nixpkgs vimPlugins attribute
      deps = { "nvim-lua/plenary.nvim" },
      cmd = { "Telescope" },
      keys = { { "<leader>ff", "<cmd>Telescope find_files<CR>" } },
      config = function() ... end,
    },
  },
}
```

---

## 2. Nix Flake & Wrapper Modules Architecture

The repository contains a declarative Nix Flake derivation ([`flake.nix`](file:///home/addy/.config/nvim/flake.nix)) and Nix module schema ([`module.nix`](file:///home/addy/.config/nvim/module.nix)).

### `module.nix` Anatomy
```nix
inputs:
{
  config,
  wlib,
  lib,
  pkgs,
  ...
}:
{
  imports = [ wlib.wrapperModules.neovim ];

  # Config directory
  config.settings.config_directory = ./.;

  # Default core runtime packages bundled directly on Neovim's PATH
  config.runtimePkgs = with pkgs; [
    lua-language-server
    nixd
    nil
    stylua
    nixfmt
    shfmt
    shellcheck
    statix
    direnv
    ripgrep
    fd
    git
    tree-sitter
  ];

  # General plugin specs list from Nixpkgs
  config.specs.general = with pkgs.vimPlugins; [
    catppuccin-nvim
    nvim-treesitter.withAllGrammars
    conform-nvim
    nvim-lint
    nvim-dap
    nvim-dap-ui
    nvim-lspconfig
    telescope-nvim
    blink-cmp
    nvim-tree-lua
    fidget-nvim
    lualine-nvim
  ];
}
```

---

## 3. Nix Path String Gotchas & `evalModules` Analysis

### The `findfile(".envrc", ".;")` Gotcha
When performing upward ancestor file searches in Vim/Neovim Lua (e.g. searching for `.envrc` in parent directories):
- **Correct**: `vim.fn.findfile(".envrc", ".;")`
- **Explanation**: `.;` is Vim's built-in upward ancestor search operator. Passing a absolute path string like `"/home/user/dir;"` fails if formatted without `.;`.

### `evalModules` & BirdeeVim Responsibility Distribution
- **Nix Layer (`module.nix` / `flake.nix`)**: Responsible for fetching `/nix/store` derivations, compiling Treesitter grammars, bundling native CLI tools (`ripgrep`, `fd`, `nixd`, `stylua`, `shellcheck`) onto `$PATH`, and bootstrapping Neovim.
- **Lua Layer (`lua/modules/`)**: Responsible for DAG execution, runtime keybindings, UI rendering, buffer state, and event handling.
- **Separation of Concerns**: Nix NEVER writes keymaps or Lua configuration logic inside Nix strings; all Lua logic lives strictly inside `.lua` files tracked in the DAG graph.
