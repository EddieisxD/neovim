--- Lualine Statusline & Top Tabline Bufferline Module
--- Displays active LSP clients, formatters, and linters on statusline, and visual tab-scoped bufferline on top tabline.

local dag_lib = require("library.dag")

local function resolve_lualine_theme(scheme)
    scheme = scheme or vim.g.colors_name or "catppuccin-mocha"
    local theme_tbl = nil

    if scheme:match("^catppuccin") then
        local flavour = scheme:gsub("^catppuccin%-", "")
        if flavour == "catppuccin" or flavour == "" then flavour = "mocha" end
        local ok_cat, cat_lualine = pcall(require, "catppuccin.utils.lualine")
        if ok_cat and type(cat_lualine) == "function" then
            local ok_res, res = pcall(cat_lualine, flavour)
            if ok_res and type(res) == "table" then
                theme_tbl = res
            end
        end
    end

    if not theme_tbl then
        local ok_l, lualine_theme = pcall(require, "lualine.themes." .. scheme:gsub("-", "_"))
        if ok_l and type(lualine_theme) == "table" then
            theme_tbl = lualine_theme
        end
    end

    -- Per lualine.nvim documentation: clear section 'c' background (bg = nil) for global container bar transparency
    if type(theme_tbl) == "table" and _G.Bundle and _G.Bundle.state and _G.Bundle.state.transparent == true then
        theme_tbl = vim.deepcopy(theme_tbl)
        for _, mode in ipairs({ "normal", "inactive", "insert", "visual", "replace", "command" }) do
            if theme_tbl[mode] and theme_tbl[mode].c then
                theme_tbl[mode].c.bg = nil
            end
            if theme_tbl[mode] and theme_tbl[mode].b then
                theme_tbl[mode].b.bg = nil
            end
        end
    end

    return theme_tbl or scheme:gsub("-", "_")
end

local function active_tools_status()
    local buf = vim.api.nvim_get_current_buf()
    local ft = vim.bo[buf].filetype
    local parts = {}

    -- Active LSP Clients
    local clients = vim.lsp.get_clients({ bufnr = buf })
    local lsp_names = {}
    for _, c in ipairs(clients) do
        table.insert(lsp_names, c.name)
    end
    if #lsp_names > 0 then
        table.insert(parts, "󰅡 " .. table.concat(lsp_names, ","))
    end

    -- Active Formatters on $PATH
    local formatters = {
        lua      = { "stylua" },
        nix      = { "nixfmt", "alejandra" },
        sh       = { "shfmt" },
        bash     = { "shfmt" },
        python   = { "black", "ruff" },
        rust     = { "rustfmt" },
        go       = { "gofmt" },
        c        = { "clang-format" },
        cpp      = { "clang-format" },
        json     = { "prettier" },
        markdown = { "prettier" },
    }
    local fmt_names = {}
    for _, f in ipairs(formatters[ft] or {}) do
        if vim.fn.executable(f) == 1 then
            table.insert(fmt_names, f)
        end
    end
    if #fmt_names > 0 then
        table.insert(parts, "󰉁 " .. table.concat(fmt_names, ","))
    end

    -- Active Linters on $PATH
    local linters = {
        nix    = { "statix", "deadnix" },
        sh     = { "shellcheck" },
        bash   = { "shellcheck" },
        lua    = { "luacheck" },
        python = { "flake8", "pylint" },
    }
    local lnt_names = {}
    for _, l in ipairs(linters[ft] or {}) do
        if vim.fn.executable(l) == 1 then
            table.insert(lnt_names, l)
        end
    end
    if #lnt_names > 0 then
        table.insert(parts, "󰃤 " .. table.concat(lnt_names, ","))
    end

    return #parts > 0 and table.concat(parts, " ") or ""
end

return {
    id = "lualine",
    phase = dag_lib.Phases.POST,
    deps = { "options", "colorscheme" },
    specs = {
        {
            name = "nvim-lualine/lualine.nvim",
            id = "lualine",
            deps = { "nvim-tree/nvim-web-devicons" },
            event = "VimEnter",
            opts = {
                options = {
                    theme = resolve_lualine_theme("catppuccin-mocha"),
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "", right = "" },
                    globalstatus = true,
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch", "diff", "diagnostics" },
                    lualine_c = { { "filename", path = 1 } },
                    lualine_x = { active_tools_status, "encoding", "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
                tabline = {
                    lualine_a = {
                        -- Left corner Normal-highlighted spacer for Ghostty terminal window padding color sampling
                        {
                            function() return " " end,
                            color = "Normal",
                            padding = 0,
                        },
                        {
                            "buffers",
                            show_filename_only = true,
                            hide_filename_extension = false,
                            show_modified_status = true,
                            mode = 0,
                            max_length = function() return vim.o.columns * 3 / 4 end,
                            symbols = {
                                modified = " ●",
                                alternate_file = "",
                                directory = "",
                            },
                            buffers_color = {
                                active = { fg = "#cdd6f4", bg = "#313244", gui = "bold" },
                                inactive = { fg = "#6c7086", bg = "NONE" },
                            },
                        },
                    },
                    lualine_z = {
                        {
                            "tabs",
                            mode = 0,
                            max_length = function() return vim.o.columns / 4 end,
                            tabs_color = {
                                active = { fg = "#cdd6f4", bg = "#313244", gui = "bold" },
                                inactive = { fg = "#6c7086", bg = "NONE" },
                            },
                        },
                        -- Right corner Normal-highlighted spacer for Ghostty terminal window padding color sampling
                        {
                            function() return " " end,
                            color = "Normal",
                            padding = 0,
                        },
                    },
                },
            },
            config = function(_, opts)
                local ok, lualine = pcall(require, "lualine")
                if ok then
                    opts.options = opts.options or {}
                    opts.options.theme = resolve_lualine_theme(vim.g.colors_name)
                    lualine.setup(opts)
                end

                -- Auto-synchronize Lualine theme non-destructively on ColorScheme event
                local augroup = vim.api.nvim_create_augroup("LualineThemeSync", { clear = true })
                vim.api.nvim_create_autocmd("ColorScheme", {
                    group = augroup,
                    callback = function()
                        local ok_l, lualine_inst = pcall(require, "lualine")
                        if ok_l and type(lualine_inst.set_theme) == "function" then
                            local resolved = resolve_lualine_theme(vim.g.colors_name)
                            pcall(lualine_inst.set_theme, resolved)
                        end
                    end,
                })
            end,
        },
    },
    exec = function() end,
}
