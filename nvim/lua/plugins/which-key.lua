return {
  {
    "folke/which-key.nvim",
    opts = {
      defaults = {
        ["<leader>o"] = { name = "oil" },
        ["<leader>op"] = { "<cmd>lua require('oil').toggle_float()<CR>", "Toggle Window (cwd)" },
      },
    },
  },
}
