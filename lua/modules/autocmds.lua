--- Autocmds Module
local dag_lib = require("library.dag")

return {
  id = "autocmds",
  phase = dag_lib.Phases.AUTOCMDS,
  deps = { "options" },
  exec = function()
    local augroup = vim.api.nvim_create_augroup("DAGAutocmds", { clear = true })

    -- Highlight on yank
    vim.api.nvim_create_autocmd("TextYankPost", {
      group = augroup,
      callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
      end,
    })
  end,
}
