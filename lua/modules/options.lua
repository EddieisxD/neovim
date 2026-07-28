--- Options Module
local dag_lib = require("library.dag")

return {
  id = "options",
  phase = dag_lib.Phases.OPTIONS,
  deps = {},
  exec = function()
    local opt = vim.opt

    opt.number = true
    opt.relativenumber = true
    opt.expandtab = true
    opt.shiftwidth = 2
    opt.tabstop = 2
    opt.smartindent = true
    opt.termguicolors = true
    opt.signcolumn = "yes"
    opt.updatetime = 250
    opt.timeoutlen = 300
    opt.ignorecase = true
    opt.smartcase = true
    opt.undofile = true
    opt.cursorline = true

    vim.g.mapleader = " "
    vim.g.maplocalleader = " "
  end,
}
