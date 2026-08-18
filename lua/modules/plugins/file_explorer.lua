--- NvimTree File Explorer Module (Sourced from NvChad)
--- Automatically syncs root directory on :cd / DirChanged and enforces borderless seamless UI.

local dag_lib = require("library.dag")

local function make_nvimtree_borderless()
  local normal_hl = vim.api.nvim_get_hl(0, { name = "NvimTreeNormal" })
  local bg_val = (normal_hl and normal_hl.bg) and normal_hl.bg or "none"

  vim.api.nvim_set_hl(0, "NvimTreeNormalNC", { link = "NvimTreeNormal" })
  vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { fg = bg_val, bg = bg_val })
  vim.api.nvim_set_hl(0, "NvimTreeVertSplit", { fg = bg_val, bg = bg_val })
end

return {
  id = "file_explorer",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options", "keymap_registry" },
  specs = {
    {
      name = "nvim-tree/nvim-tree.lua",
      id = "nvim-tree",
      enabled = not vim.g.vscode,
      deps = { "nvim-tree/nvim-web-devicons" },
      cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },

      keys = {
        { "<C-n>",      "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
        { "<leader>e",  "<cmd>NvimTreeFocus<CR>",  desc = "Focus file explorer" },
      },

      opts = {
        filters = { dotfiles = false },
        disable_netrw = true,
        hijack_netrw = true,
        hijack_cursor = true,
        sync_root_with_cwd = true,
        respect_buf_cwd = true,
        update_focused_file = {
          enable = true,
          update_root = true,
        },
        view = {
          width = 30,
          side = "left",
        },
        renderer = {
          indent_markers = {
            enable = false,
          },
        },
      },

      config = function(_, opts)
        if vim.g.vscode then return end
        local ok, tree = pcall(require, "nvim-tree")
        if ok then
          tree.setup(opts or {})
          make_nvimtree_borderless()

          local augroup = vim.api.nvim_create_augroup("DAGBorderlessNvimTree", { clear = true })
          vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
            group = augroup,
            callback = make_nvimtree_borderless,
          })
        end
      end,
    },
  },
  exec = function()
    local registry = require("modules.keymap_registry").api
    registry.bind("toggle_tree", "NvimTreeToggle", "workbench.action.toggleSidebarVisibility")
    registry.bind("focus_tree", "NvimTreeFocus", "workbench.files.action.focusFilesExplorer")
  end,
}
