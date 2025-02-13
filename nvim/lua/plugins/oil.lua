return {
  {
    "stevearc/oil.nvim",
    opts = function(_, opts)
      return opts
    end,
    config = function(_, opts)
      local oil = require("oil")
      oil.setup(opts)

      vim.keymap.set("n", "<leader>op", oil.toggle_float, { desc = "Toggle Window (cwd)" })
    end,
  },
}
