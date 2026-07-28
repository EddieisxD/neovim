--- Direnv Integration Module Spec
--- Automatically exports environment variables from direnv / nix-direnv into Neovim's vim.env.
--- Sourced automatically on VimEnter, BufEnter, and DirChanged.

local dag_lib = require("library.dag")

local function sync_direnv()
  if vim.fn.executable("direnv") ~= 1 then return end

  local ok_sys, res = pcall(function()
    return vim.system({ "direnv", "export", "json" }):wait()
  end)

  if ok_sys and res and res.code == 0 and res.stdout and #res.stdout > 0 then
    local ok_json, env_vars = pcall(vim.fn.json_decode, res.stdout)
    if ok_json and type(env_vars) == "table" then
      for k, v in pairs(env_vars) do
        if type(k) == "string" and type(v) == "string" then
          vim.env[k] = v
        end
      end
    end
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
