--- Lualine Statusline Module
--- Displays active LSP clients, formatters, and linters dynamically sourced from $PATH.

local dag_lib = require("library.dag")

local function active_tools_status()
    local buf = vim.api.nvim_get_current_buf()
    local ft = vim.bo[buf].filetype

    -- Active LSP Clients
    local clients = vim.lsp.get_clients({ bufnr = buf })
    local lsp_names = {}
    for _, c in ipairs(clients) do
        table.insert(lsp_names, c.name)
    end
    local lsp_str = #lsp_names > 0 and table.concat(lsp_names, ", ") or "off"

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
    local fmt_str = #fmt_names > 0 and table.concat(fmt_names, ",") or "lsp"

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
    local lnt_str = #lnt_names > 0 and table.concat(lnt_names, ",") or "none"

    return string.format(" lsp:[%s] fmt:[%s] lnt:[%s]", lsp_str, fmt_str, lnt_str)
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
                    theme = "auto",
                    component_separators = { left = "│", right = "│" },
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
            },
            config = function(_, opts)
                local ok, lualine = pcall(require, "lualine")
                if ok then
                    lualine.setup(opts or {})
                end
            end,
        },
    },
    exec = function() end,
}
