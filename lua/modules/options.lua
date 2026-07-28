--- Options Module (Sourced from ~/.config/nvim/lua/options.lua)
local dag_lib = require("library.dag")

return {
  id = "options",
  phase = dag_lib.Phases.OPTIONS,
  deps = {},
  exec = function()
    local opt = vim.opt
    local o = vim.o

    vim.g.netrw_banner = 0

    --- Indentations
    o.tabstop = 4
    o.softtabstop = 4
    o.shiftwidth = 4
    o.expandtab = true
    o.autoindent = true

    --- Line Wrapping
    o.wrap = true
    o.linebreak = true
    o.textwidth = 0

    --- Gutter & Line Numbers
    opt.number = true
    opt.relativenumber = true
    opt.numberwidth = 4
    opt.signcolumn = "yes"
    opt.foldcolumn = "1"
    opt.fillchars:append({ eob = " " })

    o.formatoptions = "jcroql"

    --- Mouse & Clipboard
    o.mouse = "a"
    o.mousemodel = "popup"
    opt.clipboard:append("unnamedplus")

    --- Swap & Undo Files
    o.swapfile = false
    o.backup = false
    o.writebackup = false
    o.undofile = true

    local undodir = "/tmp/neovim/"
    if vim.fn.isdirectory(undodir) == 0 then
      vim.fn.mkdir(undodir, "p")
    end
    o.undodir = undodir
    o.directory = undodir

    --- UI & Appearance
    o.termguicolors = true
    o.background = "dark"
    o.showmode = false
    o.cmdheight = 1
    o.pumheight = 10
    o.pumblend = 10
    opt.laststatus = 3

    --- Window Splits
    o.splitbelow = true
    o.splitright = true
    o.equalalways = true
    o.winminwidth = 10
    o.winminheight = 1

    --- Search Options
    o.hlsearch = true
    o.incsearch = true
    o.ignorecase = true
    o.smartcase = true
    opt.inccommand = "split"

    --- Motion & Scrolling
    o.scrolloff = 8
    o.sidescrolloff = 8
    o.timeoutlen = 500
    o.ttimeoutlen = 0
    o.updatetime = 250
    o.hidden = true

    --- Spell Check
    o.spell = false
    o.spelllang = "en_us"
    opt.spelloptions:append("camel")

    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    vim.cmd("cabbrev h tab help")
  end,
}
