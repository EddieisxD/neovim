--- Options Module
--- Reads initial settings from Bundle.state (persisted in bundle_state.json),
--- enables Neovim 0.12+ Core UI2, configures options, signcolumn expansion, and diagnostic icons with source tags.

local dag_lib = require("library.dag")

return {
  id = "options",
  phase = dag_lib.Phases.OPTIONS,
  deps = {},
  exec = function()
    local opt = vim.opt
    local o = vim.o
    local state = _G.Bundle and _G.Bundle.state or {}

    -- Enable Neovim 0.12+ Core UI2
    local ok_ui2, ui2 = pcall(require, "vim._core.ui2")
    if ok_ui2 and type(ui2.enable) == "function" then
      pcall(ui2.enable)
    end

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

    --- Gutter & Line Numbers (Clean statuscolumn with spacer between line numbers and signcolumn)
    opt.number = state.number ~= false
    opt.relativenumber = state.relativenumber ~= false
    opt.numberwidth = 4
    opt.signcolumn = "yes:2"
    opt.foldcolumn = "1"
    opt.statuscolumn = "%= %l  %s %C"

    opt.fillchars = {
      eob = " ",
      fold = " ",
      foldopen = "",
      foldclose = "",
      foldsep = " ",
    }

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

    -- Link MsgArea to Normal background
    vim.api.nvim_set_hl(0, "MsgArea", { link = "Normal" })

    -- Curated Diagnostic Signs & Floating Window Settings (Sleek Sparkle hint icon)
    vim.diagnostic.config({
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "󰅚 ",
          [vim.diagnostic.severity.WARN]  = "󰀦 ",
          [vim.diagnostic.severity.INFO]  = "󰋼 ",
          [vim.diagnostic.severity.HINT]  = "󰛩 ",
        },
      },
      virtual_text = {
        prefix = "● ",
      },
      float = {
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
      severity_sort = true,
    })

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

    --- Spell Check & Portable Dictionary
    o.spell = false
    o.spelllang = "en_us"
    opt.spelloptions:append("camel")
    opt.spellfile = vim.fn.expand("~/.config/nvim/dictionary.utf-8.add")

    vim.cmd("cabbrev h tab help")

    -- Line Number Toggle Keybindings with State Persistence
    vim.keymap.set("n", "<leader>n", function()
      local cur = opt.number:get()
      opt.number = not cur
      if _G.Bundle then
        _G.Bundle.state.number = not cur
        _G.Bundle:save_state()
      end
    end, { desc = "Toggle line number" })

    vim.keymap.set("n", "<leader>rn", function()
      local cur = opt.relativenumber:get()
      opt.relativenumber = not cur
      if _G.Bundle then
        _G.Bundle.state.relativenumber = not cur
        _G.Bundle:save_state()
      end
    end, { desc = "Toggle relative number" })
  end,
}
