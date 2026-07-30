--- Dynamic Environment-Sourced LSP Module
--- Eliminates Mason dependency by dynamically discovering LSP binaries on $PATH
--- (sourced from nix-shell, nix develop, direnv, NixOS, or system shells) and provides unified :Lsp suite.

local dag_lib = require("library.dag")
local logger = require("library.logger")

--- Registry of known Language Servers and their executable names, commands & settings
local known_servers = {
  {
    name = "nil_ls",
    bin = "nil",
    cmd = { "nil" },
    ft = { "nix" },
    settings = {
      ["nil"] = {
        formatting = { command = { "nixfmt" } },
      },
    },
  },
  {
    name = "nixd",
    bin = "nixd",
    cmd = { "nixd" },
    ft = { "nix" },
    settings = {
      nixd = {
        formatting = { command = { "nixfmt" } },
      },
    },
  },
  { name = "lua_ls",        bin = "lua-language-server",       cmd = { "lua-language-server" },       ft = { "lua" } },
  { name = "pyright",       bin = "pyright-langserver",        cmd = { "pyright-langserver", "--stdio" }, ft = { "python" } },
  { name = "pylsp",         bin = "pylsp",                     cmd = { "pylsp" },                     ft = { "python" } },
  { name = "gopls",         bin = "gopls",                     cmd = { "gopls" },                     ft = { "go", "gomod" } },
  { name = "rust_analyzer", bin = "rust-analyzer",             cmd = { "rust-analyzer" },             ft = { "rust" } },
  { name = "ts_ls",         bin = "typescript-language-server", cmd = { "typescript-language-server", "--stdio" }, ft = { "typescript", "javascript", "typescriptreact", "javascriptreact" } },
  { name = "clangd",        bin = "clangd",                    cmd = { "clangd" },                    ft = { "c", "cpp", "objc", "objcpp" } },
  { name = "bashls",        bin = "bash-language-server",      cmd = { "bash-language-server", "start" }, ft = { "sh", "bash" } },
  { name = "taplo",         bin = "taplo",                     cmd = { "taplo", "lsp", "stdio" },     ft = { "toml" } },
  { name = "yamlls",        bin = "yaml-language-server",      cmd = { "yaml-language-server", "--stdio" }, ft = { "yaml", "yml" } },
  { name = "jsonls",        bin = "vscode-json-language-server", cmd = { "vscode-json-language-server", "--stdio" }, ft = { "json", "jsonc" } },
  { name = "zls",           bin = "zls",                       cmd = { "zls" },                       ft = { "zig" } },
}

local active_servers = {}

--- Scan $PATH for available LSP executables and configure them dynamically
local function scan_and_enable_servers()
  local newly_enabled = 0

  for _, s in ipairs(known_servers) do
    if not active_servers[s.name] and vim.fn.executable(s.bin) == 1 then
      active_servers[s.name] = true
      newly_enabled = newly_enabled + 1

      logger.info(string.format("[LSP Environment Engine] Discovered binary '%s' on $PATH for LSP '%s'", s.bin, s.name))

      local server_cmd = s.cmd or { s.bin }

      if vim.lsp and vim.lsp.config then
        -- Neovim 0.11+ Native LSP API
        vim.lsp.config(s.name, {
          cmd = server_cmd,
          filetypes = s.ft,
          settings = s.settings or {},
        })
        vim.lsp.enable(s.name)
      else
        -- Fallback to nvim-lspconfig
        local ok, lspconfig = pcall(require, "lspconfig")
        if ok and lspconfig[s.name] then
          lspconfig[s.name].setup({
            cmd = server_cmd,
            settings = s.settings or {},
          })
        end
      end
    end
  end

  if newly_enabled > 0 then
    logger.info(string.format("[LSP Environment Engine] Enabled %d new LSP servers from active shell environment", newly_enabled))
  end
end

return {
  id = "lsp",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options", "keymaps" },
  specs = {
    {
      name = "neovim/nvim-lspconfig",
      id = "nvim-lspconfig",
      event = { "BufReadPre", "BufNewFile" },
      config = function()
        scan_and_enable_servers()
      end,
    },
  },

  exec = function()
    -- Initial environment scan
    scan_and_enable_servers()

    -- Unified :Lsp <subcommand> [lsp_name] command suite
    local lsp_subcommands = { "enable", "disable", "restart", "stop", "start", "info" }

    local function lsp_complete(arg_lead, cmd_line, cursor_pos)
      local parts = vim.split(cmd_line, "%s+", { trimempty = true })
      if #parts == 1 or (#parts == 2 and not cmd_line:match("%s$")) then
        local matches = {}
        for _, sub in ipairs(lsp_subcommands) do
          if sub:find(arg_lead, 1, true) == 1 then
            table.insert(matches, sub)
          end
        end
        return matches
      elseif #parts >= 2 then
        local matches = {}
        for _, s in ipairs(known_servers) do
          if s.name:find(arg_lead, 1, true) == 1 then
            table.insert(matches, s.name)
          end
        end
        return matches
      end
      return {}
    end

    vim.api.nvim_create_user_command("Lsp", function(opts)
      local args = vim.split(opts.args, "%s+", { trimempty = true })
      local sub = args[1]
      local name = args[2]

      if not sub or sub == "info" then
        local clients = vim.lsp.get_clients()
        local active_names = {}
        for _, c in ipairs(clients) do
          table.insert(active_names, c.name)
        end
        local msg = "Active LSP Clients: " .. (#active_names > 0 and table.concat(active_names, ", ") or "None")
        if _G.Bundle and _G.Bundle.notify then
          _G.Bundle:notify(msg, vim.log.levels.INFO, { title = "LSP" })
        else
          vim.notify(msg, vim.log.levels.INFO, { title = "LSP" })
        end
      elseif sub == "restart" then
        if name then
          local clients = vim.lsp.get_clients({ name = name })
          for _, c in ipairs(clients) do
            vim.lsp.stop_client(c.id)
          end
          pcall(vim.lsp.enable, name)
        else
          pcall(vim.cmd, "LspRestart")
        end
      elseif sub == "stop" or sub == "disable" then
        if name then
          local clients = vim.lsp.get_clients({ name = name })
          for _, c in ipairs(clients) do
            vim.lsp.stop_client(c.id)
          end
          vim.notify("Stopped LSP: " .. name, vim.log.levels.INFO, { title = "LSP" })
        else
          for _, c in ipairs(vim.lsp.get_clients()) do
            vim.lsp.stop_client(c.id)
          end
          vim.notify("Stopped all LSP clients", vim.log.levels.INFO, { title = "LSP" })
        end
      elseif sub == "start" or sub == "enable" then
        if name then
          if vim.lsp and vim.lsp.enable then
            pcall(vim.lsp.enable, name)
          end
          vim.notify("Enabled LSP: " .. name, vim.log.levels.INFO, { title = "LSP" })
        else
          scan_and_enable_servers()
        end
      end
    end, {
      nargs = "*",
      complete = lsp_complete,
      desc = "Unified LSP Management Suite (:Lsp enable|disable|restart|stop|start|info <name>)",
    })

    vim.cmd("cabbrev lsp Lsp")

    -- Auto-rescan environment on direnv reload or directory change
    local augroup = vim.api.nvim_create_augroup("LspEnvironmentScanner", { clear = true })
    vim.api.nvim_create_autocmd({ "DirChanged", "BufReadPost" }, {
      group = augroup,
      callback = function()
        scan_and_enable_servers()
      end,
    })
  end,
}
