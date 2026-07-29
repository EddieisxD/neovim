--- Direnv Integration Module Spec
--- Automatically exports environment variables from direnv / nix-direnv into Neovim's process environment block (vim.fn.setenv & vim.env)
--- on VimEnter, BufEnter, and DirChanged, with non-blocking Fidget notifications.

local dag_lib = require("library.dag")

local function sync_direnv(target_dir)
  if vim.fn.executable("direnv") ~= 1 then return end

  target_dir = target_dir or vim.fn.getcwd()

  -- Search for .envrc or .env file in target_dir or any of its parent directories
  local env_file = vim.fn.findfile(".envrc", target_dir .. ";")
  if env_file == "" then
    env_file = vim.fn.findfile(".env", target_dir .. ";")
  end
  if env_file == "" then return end

  local env_dir = vim.fn.fnamemodify(env_file, ":p:h")

  local ok_sys, res = pcall(function()
    return vim.system({ "direnv", "export", "json" }, { cwd = env_dir }):wait()
  end)

  local synced_count = 0
  if ok_sys and res and res.code == 0 and res.stdout and #res.stdout > 0 then
    local ok_json, env_vars = pcall(vim.fn.json_decode, res.stdout)
    if ok_json and type(env_vars) == "table" then
      for k, v in pairs(env_vars) do
        if type(k) == "string" and type(v) == "string" then
          vim.env[k] = v
          vim.fn.setenv(k, v)
          synced_count = synced_count + 1
        end
      end
    end
  end

  -- Send notification via Fidget
  if synced_count > 0 then
    local ok_fidget, fidget = pcall(require, "fidget")
    if ok_fidget and type(fidget.notify) == "function" then
      pcall(fidget.notify, "Loaded direnv (" .. synced_count .. " vars) for " .. env_dir, vim.log.levels.INFO, { title = "direnv" })
    end
  end
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
  end,
}
