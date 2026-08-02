--- HBAC (Heuristic Buffer Auto-Close) Module
--- Automatically closes unedited background buffers when open buffer count exceeds threshold.

local dag_lib = require("library.dag")

return {
  id = "hbac",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "axkirillov/hbac.nvim",
      id = "hbac",
      event = "BufReadPost",
      opts = {
        autopin = true,       -- Automatically pin buffers when modified
        threshold = 10,       -- Auto-close unedited buffers when count exceeds 10
        close_command = function(bufnr)
          local ok = pcall(vim.cmd, "bdelete " .. bufnr)
          if not ok then pcall(vim.cmd, "bdelete! " .. bufnr) end
        end,
      },
      config = function(_, opts)
        local ok, hbac = pcall(require, "hbac")
        if ok then
          hbac.setup(opts)
        end
      end,
    },
  },
  exec = function() end,
}
