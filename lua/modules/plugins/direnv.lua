--- Direnv Integration Module Spec
--- Automatically exports environment variables from direnv / nix-direnv into Neovim's process environment block (vim.fn.setenv & vim.env)
--- with target buffer directory resolution, Fidget progress notifications, and strict atomic isolation.

local dag_lib = require("library.dag")

local function sync_direnv(opts)
  if vim.fn.executable("direnv") ~= 1 then return end

  -- Determine target directory from active buffer path or current working directory
  local buf_path = vim.api.nvim_buf_get_name(0)
  local target_dir = (buf_path ~= "" and vim.fn.fnamemodify(buf_path, ":p:h")) or vim.fn.getcwd()

  -- Search for .envrc or .env file in target_dir or any of its parent directories
  local env_file = vim.fn.findfile(".envrc", target_dir .. ";")
  if env_file == "" then
    env_file = vim.fn.findfile(".env", target_dir .. ";")
  end
  if env_file == "" then return end

  -- Resolve actual directory containing the .envrc
  local env_dir = vim.fn.fnamemodify(env_file, ":p:h")

  -- Create Fidget progress notification if Fidget is available
  local ok_fidget, fidget = pcall(require, "fidget")
  local progress_handle = nil
  if ok_fidget and fidget.progress and type(fidget.progress.handle) == "table" and type(fidget.progress.handle.create) == "function" then
    pcall(function()
      progress_handle = fidget.progress.handle.create({
        title = "direnv",
        message = "Syncing Nix shell environment...",
        lsp_client = { name = "direnv" },
      })
    end)
  end

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

  -- Finish Fidget notification
  if progress_handle then
    pcall(function()
      if synced_count > 0 then
        progress_handle.message = "Environment synced (" .. synced_count .. " variables)"
      else
        progress_handle.message = "Environment sync complete"
      end
      progress_handle:finish()
    end)
  end
end

return {
  id = "direnv",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "direnv/direnv.vim",
      id = "direnv",
      nix_name = "direnv-vim",
      lazy = false,
      priority = 100,
      config = function()
        sync_direnv()

        local augroup = vim.api.nvim_create_augroup("DAGDirenvSync", { clear = true })
        vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter", "DirChanged" }, {
          group = augroup,
          callback = function()
            sync_direnv()
          end,
        })
      end,
    },
  },
  exec = function()
    sync_direnv()
  end,
}
