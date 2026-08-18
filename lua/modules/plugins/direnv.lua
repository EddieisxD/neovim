--- Direnv Integration Module Spec
--- Automatically exports environment variables from direnv / nix-direnv into Neovim's process environment block (vim.fn.setenv & vim.env)
--- asynchronously on VimEnter and DirChanged with Fidget progress spinner animations and interactive Direnv commands.

local dag_lib = require("library.dag")

local last_synced_dir = nil

local function sync_direnv(target_dir, verbose, force)
  if vim.fn.executable("direnv") ~= 1 then return end

  target_dir = (target_dir and target_dir ~= "") and target_dir or vim.fn.getcwd()

  -- Use Vim's upward ancestor search operator (target_dir .. ";.") to find .envrc / .env in target or parent directories
  local search_path = target_dir .. ";."
  local env_file = vim.fn.findfile(".envrc", search_path)
  if env_file == "" then
    env_file = vim.fn.findfile(".env", search_path)
  end
  if env_file == "" then return end

  local env_dir = vim.fn.fnamemodify(env_file, ":p:h")

  -- Skip sync if already synced for this exact env_dir (unless forced)
  if not force and last_synced_dir == env_dir then return end

  -- Create Fidget progress handle spinner animation
  local ok_fidget, fidget = pcall(require, "fidget")
  local progress_handle = nil
  if ok_fidget and fidget.progress and type(fidget.progress.handle) == "table" and type(fidget.progress.handle.create) == "function" then
    pcall(function()
      progress_handle = fidget.progress.handle.create({
        title = "direnv",
        message = "Syncing Nix environment...",
        lsp_client = { name = "direnv" },
      })
    end)
  end

  -- Asynchronous non-blocking process spawn
  vim.system({ "direnv", "export", "json" }, { cwd = env_dir }, function(res)
    vim.schedule(function()
      local synced_count = 0
      local is_success = res and res.code == 0 and res.stdout and #res.stdout > 0

      if is_success then
        local ok_json, env_vars = pcall(vim.fn.json_decode, res.stdout)
        if ok_json and type(env_vars) == "table" then
          for k, v in pairs(env_vars) do
            if type(k) == "string" and type(v) == "string" then
              vim.env[k] = v
              vim.fn.setenv(k, v)
              synced_count = synced_count + 1
            end
          end
          last_synced_dir = env_dir
          -- Emit decoupled User DirenvLoaded event so dependent systems (LSP scanner, Lualine) update reactively
          pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "DirenvLoaded" })
        end
      end

      -- Finish Fidget progress animation cleanly
      if progress_handle then
        pcall(function()
          if is_success and synced_count > 0 then
            progress_handle.message = "Loaded direnv (" .. synced_count .. " vars)"
          elseif verbose then
            progress_handle.message = "Sync failed (check direnv status)"
          else
            progress_handle.message = "Environment ready"
          end
          progress_handle:finish()
        end)
      elseif is_success and (synced_count > 0 or verbose) then
        local msg = "Loaded direnv (" .. synced_count .. " vars) for " .. env_dir
        if _G.Bundle and type(_G.Bundle.notify) == "function" then
          _G.Bundle:notify(msg, vim.log.levels.INFO, { title = "direnv" })
        else
          vim.notify(msg, vim.log.levels.INFO, { title = "direnv" })
        end
      end
    end)
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
        sync_direnv(nil, false, true)

        local augroup = vim.api.nvim_create_augroup("DAGDirenvSync", { clear = true })
        vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
          group = augroup,
          callback = function(args)
            local cwd = (args.event == "DirChanged" and args.file) or vim.fn.getcwd()
            sync_direnv(cwd, false, args.event == "DirChanged")
          end,
        })
      end,
    },
  },
  exec = function()
    sync_direnv(nil, false, true)

    -- Interactive Direnv user commands
    vim.api.nvim_create_user_command("DirenvExport", function()
      sync_direnv(nil, true, true)
    end, { desc = "Export/reload direnv environment for current CWD" })

    vim.api.nvim_create_user_command("DirenvReload", function()
      sync_direnv(nil, true, true)
    end, { desc = "Export/reload direnv environment for current CWD" })

    vim.api.nvim_create_user_command("DirenvAllow", function()
      local cwd = vim.fn.getcwd()
      vim.system({ "direnv", "allow" }, { cwd = cwd }, function(res)
        vim.schedule(function()
          if res.code == 0 then
            sync_direnv(cwd, true, true)
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
          last_synced_dir = nil
          vim.notify("direnv deny executed for " .. cwd, vim.log.levels.INFO, { title = "direnv" })
        end)
      end)
    end, { desc = "Execute direnv deny in current CWD" })

    vim.api.nvim_create_user_command("DirenvStatus", function()
      local cwd = vim.fn.getcwd()
      local search_path = cwd .. ";."
      local env_file = vim.fn.findfile(".envrc", search_path)
      if env_file == "" then env_file = vim.fn.findfile(".env", search_path) end
      if env_file ~= "" then
        vim.notify("Direnv file found: " .. env_file .. " (Last synced: " .. tostring(last_synced_dir) .. ")", vim.log.levels.INFO, { title = "direnv" })
      else
        vim.notify("No .envrc or .env file found in " .. cwd, vim.log.levels.WARN, { title = "direnv" })
      end
    end, { desc = "Show direnv status for current CWD" })

    -- Safe command-position abbreviation
    vim.cmd([[cabbrev <expr> direnv (getcmdtype() == ':' && getcmdline() ==# 'direnv') ? 'DirenvStatus' : 'direnv']])
  end,
}
