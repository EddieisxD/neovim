--- GUI & Headless Integration Module
--- Configures smooth animations, font rendering, padding, and opacity for Neovide,
--- and adapts layout when running inside VSCode / VSCodium or headless environments.

local dag_lib = require("library.dag")
local logger = require("library.logger")

return {
  id = "gui",
  phase = dag_lib.Phases.SETUP + 5,
  deps = {},
  exec = function()
    -- 1. Neovide GUI Settings
    if vim.g.neovide then
      logger.info("[GUI Engine] Neovide GUI detected. Applying Neovide options...")

      vim.g.neovide_opacity = 0.65
      vim.g.neovide_padding_top = 24
      vim.g.neovide_padding_bottom = 12
      vim.g.neovide_padding_left = 12
      vim.g.neovide_padding_right = 12

      vim.g.neovide_cursor_animation_length = 0.08
      vim.g.neovide_cursor_trail_size = 0.8
      vim.g.neovide_cursor_vfx_mode = "railgun"
      vim.g.neovide_remember_window_size = false
      vim.g.neovide_confirm_quit = true
      vim.g.neovide_input_macos_alt_is_meta = true

      vim.opt.guifont = "JetBrainsMono Nerd Font:h13"
    end

    -- 2. VSCode / VSCodium Extension Settings
    if vim.g.vscode then
      logger.info("[GUI Engine] VSCode/VSCodium environment detected. Adapting controls...")

      -- Disable conflicting TUI options when embedded in VSCode
      vim.opt.cmdheight = 1
      vim.opt.laststatus = 0

      -- VSCode keybinding bridges
      local set = vim.keymap.set
      set("n", "<leader>ff", "<cmd>call VSCodeNotify('workbench.action.quickOpen')<CR>", { desc = "VSCode Quick Open" })
      set("n", "<leader>fw", "<cmd>call VSCodeNotify('workbench.action.findInFiles')<CR>", { desc = "VSCode Search in Files" })
      set("n", "<leader>e", "<cmd>call VSCodeNotify('workbench.action.toggleSidebarVisibility')<CR>", { desc = "VSCode Toggle Sidebar" })
    end
  end,
}
