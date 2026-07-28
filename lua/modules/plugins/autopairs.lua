--- Auto-pairs Module Spec
local dag_lib = require("library.dag")

return {
  id = "autopairs",
  phase = dag_lib.Phases.PLUGINS,
  deps = { "options" },
  specs = {
    {
      name = "windwp/nvim-autopairs",
      nix_name = "nvim-autopairs",
      id = "nvim-autopairs",
      event = "InsertEnter",
      opts = {
        fast_wrap = {},
        disable_filetype = { "TelescopePrompt", "vim" },
      },
      config = function(_, opts)
        local ok, autopairs = pcall(require, "nvim-autopairs")
        if ok then
          autopairs.setup(opts or {})
        end
      end,
    },
  },
  exec = function() end,
}
