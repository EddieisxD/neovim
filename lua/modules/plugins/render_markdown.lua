--- Render Markdown & PKM Integration Module
--- Visual Markdown rendering via render-markdown.nvim + PKM Checkbox Toggling & Clipboard Image Pasting.

local dag_lib = require("library.dag")

--- Cycle checkbox states [ ] -> [/] -> [x] -> [ ]
local function toggle_checkbox()
  local line = vim.api.nvim_get_current_line()
  if line:match("%[% %]") then
    line = line:gsub("%[% %]", "[/]", 1)
  elseif line:match("%[%/%]") then
    line = line:gsub("%[%/%]", "[x]", 1)
  elseif line:match("%[x%]") then
    line = line:gsub("%[x%]", "[ ]", 1)
  elseif line:match("%[%-%]") then
    line = line:gsub("%[%-%]", "[ ]", 1)
  end
  vim.api.nvim_set_current_line(line)
end

--- Paste image from system clipboard (wl-paste / xclip / pngpaste) into ./assets/ and insert link
local function paste_image_from_clipboard()
  local cwd = vim.fn.expand("%:p:h")
  local assets_dir = cwd .. "/assets"
  if vim.fn.isdirectory(assets_dir) == 0 then
    vim.fn.mkdir(assets_dir, "p")
  end

  local filename = "image_" .. os.date("%Y%m%d_%H%M%S") .. ".png"
  local filepath = assets_dir .. "/" .. filename
  local rel_path = "./assets/" .. filename

  local cmd = nil
  if vim.fn.executable("wl-paste") == 1 then
    cmd = { "wl-paste", "--type", "image/png" }
  elseif vim.fn.executable("xclip") == 1 then
    cmd = { "xclip", "-selection", "clipboard", "-t", "image/png", "-o" }
  elseif vim.fn.executable("pngpaste") == 1 then
    cmd = { "pngpaste", filepath }
  end

  if not cmd then
    vim.notify("No clipboard image tool found (install wl-clipboard, xclip, or pngpaste)", vim.log.levels.WARN, { title = "PKM Paste Image" })
    return
  end

  if cmd[1] ~= "pngpaste" then
    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 or #out == 0 then
      vim.notify("No image found in clipboard", vim.log.levels.WARN, { title = "PKM Paste Image" })
      return
    end
    local f = io.open(filepath, "wb")
    if f then
      f:write(out)
      f:close()
    end
  end

  local link_str = string.format("![[%s]]", rel_path)
  vim.api.nvim_put({ link_str }, "c", true, true)
  vim.notify("Pasted image to " .. rel_path, vim.log.levels.INFO, { title = "PKM Paste Image" })
end

return {
  id = "render_markdown",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "treesitter" },
  specs = {
    {
      name = "MeanderingProgrammer/render-markdown.nvim",
      id = "render-markdown",
      ft = { "markdown" },
      deps = { "nvim-treesitter/nvim-treesitter" },
      opts = {
        heading = { enabled = true },
        code = { enabled = true },
        checkbox = { enabled = true },
        bullet = {
          icons = { "●", "○", "⦿", "⊙" },
        },
      },
      config = function(_, opts)
        local ok, rm = pcall(require, "render-markdown")
        if ok then rm.setup(opts) end

        -- PKM Keybindings for Markdown files
        local set = vim.keymap.set
        set("n", "<leader>mc", toggle_checkbox, { desc = "PKM: Cycle Checkbox [ ] -> [/] -> [x]" })
        set("n", "<leader>tc", toggle_checkbox, { desc = "PKM: Cycle Checkbox [ ] -> [/] -> [x]" })
        set("n", "<leader>mp", paste_image_from_clipboard, { desc = "PKM: Paste Image from Clipboard" })
        set("n", "<leader>pi", paste_image_from_clipboard, { desc = "PKM: Paste Image from Clipboard" })
      end,
    },
  },
  exec = function() end,
}
