--- Telescope Module Spec
--- Features custom 30/70 preview layout, Doom Emacs M-x command palette picker, eager loading, and instant CWD resolution.

local dag_lib = require("library.dag")

return {
    id = "telescope",
    phase = dag_lib.Phases.PLUGINS,
    deps = { "options", "keymaps", "keymap_registry" },
    specs = {
        {
            name = "nvim-telescope/telescope.nvim",
            id = "telescope",
            enabled = not vim.g.vscode,
            lazy = false,
            priority = 80,
            deps = { "nvim-lua/plenary.nvim" },

            keys = {
                { "<A-x>",      "<cmd>Telescope commands<cr>",                                          desc = "Command Palette" },
                { "<leader>c",  "<cmd>Telescope commands<cr>",                                          desc = "Command Palette" },
                { "<leader>ff", "<cmd>Telescope find_files<cr>",                                        desc = "Find Files" },
                { "<leader>fw", "<cmd>Telescope live_grep<cr>",                                         desc = "Live Grep" },
                { "<leader>fg", "<cmd>Telescope live_grep<cr>",                                         desc = "Live Grep" },
                { "<leader>fb", "<cmd>Telescope buffers<cr>",                                           desc = "Find Buffers" },
                { "<leader>fh", "<cmd>Telescope help_tags<cr>",                                         desc = "Help Tags" },
                { "<leader>fa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<cr>", desc = "Find All Files" },
            },

            config = function()
                if vim.g.vscode then return end
                local ok, telescope = pcall(require, "telescope")
                if not ok then return end

                local vimgrep_args = {
                    "rg",
                    "--color=never",
                    "--no-heading",
                    "--with-filename",
                    "--line-number",
                    "--column",
                    "--smart-case",
                }

                telescope.setup({
                    defaults = {
                        vimgrep_arguments = vimgrep_args,
                        layout_strategy = "horizontal",
                        layout_config = {
                            prompt_position = "bottom",
                            horizontal = {
                                preview_width = 0.70,
                                results_width = 0.30,
                            },
                            width = 0.90,
                            height = 0.90,
                        },
                    },
                })
            end,
        },
    },
    exec = function()
        local registry = require("modules.keymap_registry").api
        registry.bind("find_files", "Telescope find_files", "workbench.action.quickOpen")
        registry.bind("live_grep", "Telescope live_grep", "workbench.action.findInFiles")
        registry.bind("find_buffers", "Telescope buffers", "workbench.action.showAllEditors")
    end,
}
