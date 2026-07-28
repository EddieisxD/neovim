--- Transparency Module (Sourced from ~/.config/nvim/lua/transparent_nvim.lua)
local dag_lib = require("library.dag")

local function apply_transparency()
  local groups = {
    "Normal", "NormalNC",
    "NonText", "EndOfBuffer",
    "SignColumn",
    "LineNr", "FoldColumn",
    "VertSplit",
    "StatusLine", "StatusLineNC",
    "TabLineFill",
    "MsgArea",
  }
  for _, g in ipairs(groups) do
    vim.api.nvim_set_hl(0, g, { bg = "none" })
  end
end

return {
  id = "transparency",
  phase = dag_lib.Phases.POST,
  deps = { "colorscheme" },
  exec = function()
    local augroup = vim.api.nvim_create_augroup("TransparentNvim", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = augroup,
      callback = apply_transparency,
    })

    apply_transparency()
  end,
}
