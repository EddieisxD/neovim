--- Direnv Integration Module Spec
--- Automatically exports environment variables from direnv / nix-direnv into Neovim's process environment block (vim.fn.setenv & vim.env)
--- asynchronously on VimEnter, BufEnter, and DirChanged, and provides interactive Direnv commands.

local dag_lib = require("library.dag")

local function sync_direnv(target_dir, verbose)
  if vim.fn.executable("direnv") ~= 1 then return end

  target_dir = target_dir or vim.fn.getcwd()

  local env_file = vim.fn.findfile(".envrc", target_dir .. ";")
  if env_file == "" then
    env_file = vim.fn.findfile(".env", target_dir .. ";")
  end
  if env_file == "" then return end

  local env_dir = vim.fn.fnamemodify(env_file, ":p:h")

  vim.system({ "direnv", "export", "json" }, { cwd = env_dir }, function(res)
    if res and res.code == 0 and res.stdout and #res.stdout > 0 then
      vim.schedule(function()
        local ok_json, env_vars = pcall(vim.fn.json_decode, res.stdout)
        local synced_count = 0
        if ok_json and type(env_vars) == "table" then
          for k, v in pairs(env_vars) do
            if type(k) == "string" and type(v) == "string" then
              vim.env[k] = v
              vim.fn.setenv(k, v)
              synced_count = synced_count + 1
            end
          end
        end

        if synced_count > 0 or verbose then
          local msg = "Loaded direnv (" .. synced_count .. " vars) for " .. env_dir
          if _G.Bundle and type(_G.Bundle.notify) == "function" then
            _G.Bundle:notify(msg, vim.log.levels.INFO, { title = "direnv" })
          else
            vim.notify(msg, vim.log.levels.INFO, { title = "direnv" })
          end
        end
      end)
    end
  end)
end

return {
  id = "direnv",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "NotAShelf/direnv.nvim",
      id = "direnv",
      nix_name = "direnv-nvim",
      lazy = false,
      priority = 100,
      config = function()
        local ok, direnv = pcall(require, "direnv")
        if ok then
          direnv.setup({})
        end

        sync_direnv()

        local augroup = vim.api.nvim_create_augroup("DAGDirenvSync", { clear = true })
        vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter", "DirChanged" }, {
          group = augroup,
          callback = function(args)
            local cwd = (args.event == "DirChanged" and args.file) or vim.fn.getcwd()
            sync_direnv(cwd)
          end,
        })
      end,
    },
  },
  exec = function()
    sync_direnv()

    -- Interactive Direnv user commands
    vim.api.nvim_create_user_command("DirenvExport", function()
      sync_direnv(nil, true)
    end, { desc = "Export/reload direnv environment for current CWD" })

    vim.api.nvim_create_user_command("DirenvReload", function()
      sync_direnv(nil, true)
    end, { desc = "Export/reload direnv environment for current CWD" })

    vim.api.nvim_create_user_command("DirenvAllow", function()
      local cwd = vim.fn.getcwd()
      vim.system({ "direnv", "allow" }, { cwd = cwd }, function(res)
        vim.schedule(function()
          if res.code == 0 then
            sync_direnv(cwd, true)
          else
            vim.notify("direnv allow failed: " .. (res.stderr or ""), vim.log.levels.ERROR, { title = "direnv" })
          end
        end)
      end)
    end, { desc = "Execute direnv allow in current CWD" })

    vim.api.nvim_create_user_command("DirenvDeny", function()
      local cwd = vim.fn.getcwd()
      vim.system({ "direnv", "deny" }, { cwd = cwd }, function(res)
        vim.schedule(function()
          vim.notify("direnv deny executed for " .. cwd, vim.log.levels.INFO, { title = "direnv" })
        end)
      end)
    end, { desc = "Execute direnv deny in current CWD" })

    vim.api.nvim_create_user_command("DirenvStatus", function()
      local cwd = vim.fn.getcwd()
      local env_file = vim.fn.findfile(".envrc", cwd .. ";")
      if env_file == "" then env_file = vim.fn.findfile(".env", cwd .. ";") end
      if env_file ~= "" then
        vim.notify("Direnv file found: " .. env_file, vim.log.levels.INFO, { title = "direnv" })
      else
        vim.notify("No .envrc or .env file found in " .. cwd, vim.log.levels.WARN, { title = "direnv" })
      end
    end, { desc = "Show direnv status for current CWD" })
  end,
}
