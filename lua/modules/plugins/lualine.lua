--- Lualine Statusline & Top Tabline Bufferline Module
--- Displays active LSP clients, formatters, and linters on statusline, project root directory on lualine_c,
--- and visual tab-scoped bufferline on top tabline.

local dag_lib = require("library.dag")

local function resolve_lualine_theme(scheme)
    scheme = scheme or (_G.Bundle and _G.Bundle.state and _G.Bundle.state.colorscheme) or vim.g.colors_name or "catppuccin-mocha"
    local theme_tbl = nil

    -- 1. Catppuccin special handling via catppuccin's lualine generator
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

    -- 2. Try loading explicit Lualine theme module for the scheme
    if not theme_tbl then
        local clean_name = scheme:gsub("-", "_")
        local ok_l, lualine_theme = pcall(require, "lualine.themes." .. clean_name)
        if ok_l and type(lualine_theme) == "table" then
            theme_tbl = lualine_theme
        else
            local ok_h, lualine_h = pcall(require, "lualine.themes." .. scheme)
            if ok_h and type(lualine_h) == "table" then
                theme_tbl = lualine_h
            end
        end
    end

    -- 3. If transparent, clear background on section 'c' and 'b' for global container bar transparency
    if type(theme_tbl) == "table" and _G.Bundle and _G.Bundle.state and _G.Bundle.state.transparent == true then
        theme_tbl = vim.deepcopy(theme_tbl)
        for _, mode in pairs(theme_tbl) do
            if type(mode) == "table" then
                if mode.c then mode.c.bg = nil end
                if mode.b then mode.b.bg = nil end
            end
        end
        return theme_tbl
    end

    -- Return resolved theme table or "auto" fallback (Lualine auto-samples active colorscheme highlights!)
    return theme_tbl or "auto"
end

local function root_dir_display()
    local cwd = vim.fn.getcwd()
    local folder = vim.fn.fnamemodify(cwd, ":t")
    return "󰉋 " .. folder
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
            enabled = not vim.g.vscode,
            deps = { "nvim-tree/nvim-web-devicons" },
            event = "VimEnter",
            opts = {
                options = {
                    theme = "auto",
                    component_separators = { left = "|", right = "|" },
                    section_separators = { left = "", right = "" },
                    globalstatus = true,
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch", "diff", "diagnostics" },
                    lualine_c = { root_dir_display },
                    lualine_x = { active_tools_status, "filetype" },
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
                            padding = { left = 2, right = 2 },
                            max_length = function() return vim.o.columns * 3 / 4 end,
                            symbols = {
                                modified = " ●",
                                alternate_file = "",
                                directory = "",
                            },
                            buffers_color = {
                                active = "TabLineSel",
                                inactive = "TabLine",
                            },
                            separator = { left = "", right = "" },
                        },
                    },
                    lualine_z = {
                        {
                            "tabs",
                            mode = 0,
                            padding = { left = 2, right = 2 },
                            max_length = function() return vim.o.columns / 4 end,
                            tabs_color = {
                                active = "TabLineSel",
                                inactive = "TabLine",
                            },
                            separator = { left = "", right = "" },
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
                if vim.g.vscode then return end
                local ok, lualine = pcall(require, "lualine")
                if ok then
                    local scheme = (_G.Bundle and _G.Bundle.state and _G.Bundle.state.colorscheme) or vim.g.colors_name or "catppuccin-mocha"
                    opts.options = opts.options or {}
                    opts.options.theme = resolve_lualine_theme(scheme)
                    lualine.setup(opts)
                end

                -- Synchronize Lualine setup across both sections and tabline on ColorScheme event
                local augroup = vim.api.nvim_create_augroup("LualineThemeSync", { clear = true })
                vim.api.nvim_create_autocmd("ColorScheme", {
                    group = augroup,
                    callback = function(ev)
                        local ok_l, lualine_inst = pcall(require, "lualine")
                        if ok_l then
                            local scheme = (ev and ev.match ~= "" and ev.match) or vim.g.colors_name or "catppuccin-mocha"
                            opts.options = opts.options or {}
                            opts.options.theme = resolve_lualine_theme(scheme)
                            pcall(lualine_inst.setup, opts)
                        end
                    end,
                })
            end,
        },
    },
    exec = function() end,
}
