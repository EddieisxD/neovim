inputs:
{
  config,
  wlib,
  lib,
  pkgs,
  options,
  ...
}:
{
  imports = [ wlib.wrapperModules.neovim ];

  options.nvim-lib.neovimPlugins = lib.mkOption {
    readOnly = true;
    type = lib.types.attrsOf wlib.types.stringable;
    default = config.nvim-lib.pluginsFromPrefix "plugins-" inputs;
  };

  # Config directory
  config.settings.config_directory = ./.;

  # Configure lze and lzextras specs
  config.specs.lze = [
    config.nvim-lib.neovimPlugins.lze
    {
      data = config.nvim-lib.neovimPlugins.lzextras;
      name = "lzextras";
    }
  ];

  # Default core runtime packages bundled directly on Neovim's PATH (matching wrapper_modules)
  config.runtimePkgs = with pkgs; [
    # Core LSPs
    lua-language-server
    nixd
    nil

    # Formatters & Linters
    stylua
    nixfmt
    shfmt
    shellcheck
    statix

    # Environment & Utilities
    direnv
    ripgrep
    fd
    git
    tree-sitter
  ];

  # General plugin specs list
  config.specs.general = with pkgs.vimPlugins; [
    catppuccin-nvim
    oxocarbon-nvim
    nightfox-nvim
    kanagawa-nvim
    gruvbox-material
    vague-nvim
    nvim-treesitter.withAllGrammars
    nvim-treesitter-textobjects
    direnv-vim
    nvim-lspconfig
    telescope-nvim
    plenary-nvim
    blink-cmp
    nvim-tree-lua
    nvim-web-devicons
    render-markdown-nvim
    fidget-nvim
    lualine-nvim
    mason-nvim
    mason-lspconfig-nvim
    nvim-autopairs
    which-key-nvim
  ];

  options.nvim-lib.pluginsFromPrefix = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default =
      prefix: inputs:
      lib.pipe inputs [
        builtins.attrNames
        (builtins.filter (s: lib.hasPrefix prefix s))
        (map (
          input:
          let
            name = lib.removePrefix prefix input;
          in
          {
            inherit name;
            value = config.nvim-lib.mkPlugin name inputs.${input};
          }
        ))
        builtins.listToAttrs
      ];
  };
}
