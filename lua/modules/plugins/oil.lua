--- Oil.nvim Editable Buffer File Explorer Module
--- Edit filesystem directories like a native Vim buffer with instant file operations and - keymap.

local dag_lib = require("library.dag")

return {
  id = "oil",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options", "keymap_registry" },
  specs = {
    {
      name = "stevearc/oil.nvim",
      id = "oil",
      cmd = { "Oil" },
      keys = {
        { "-", "<cmd>Oil<CR>", desc = "Open parent directory in Oil file editor" },
      },
      opts = {
        default_file_explorer = false,
        columns = {
          "icon",
          "permissions",
          "size",
          "mtime",
        },
        keymaps = {
          ["g?"] = "actions.show_help",
          ["<CR>"] = "actions.select",
          ["<C-s>"] = "actions.select_vsplit",
          ["<C-h>"] = "actions.select_split",
          ["<C-t>"] = "actions.select_tab",
          ["<C-p>"] = "actions.preview",
          ["<C-c>"] = "actions.close",
          ["<C-l>"] = "actions.refresh",
          ["-"] = "actions.parent",
          ["_"] = "actions.open_cwd",
          ["`"] = "actions.cd",
          ["~"] = "actions.tcd",
          ["gs"] = "actions.change_sort",
          ["gx"] = "actions.open_external",
          ["g."] = "actions.toggle_hidden",
          ["g\\"] = "actions.toggle_trash",
        },
        view_options = {
          show_hidden = true,
          is_hidden_file = function(name, bufnr)
            return vim.startswith(name, ".")
          end,
          is_always_hidden = function(name, bufnr)
            return false
          end,
        },
      },
      config = function(_, opts)
        local ok, oil = pcall(require, "oil")
        if ok then
          oil.setup(opts)
        end
      end,
    },
  },
  exec = function()
    vim.api.nvim_create_user_command("OilExplorer", function()
      pcall(vim.cmd, "Oil")
    end, { desc = "Open editable buffer file explorer" })
  end,
}
