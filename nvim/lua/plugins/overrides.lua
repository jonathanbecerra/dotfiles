return {
  -- Change configuration for trouble.nvim
  {
    -- Plugin: trouble.nvim
    -- URL: https://github.com/folke/trouble.nvim
    -- Description: A pretty list for showing diagnostics, references, telescope results, quickfix and location lists.
    "folke/trouble.nvim",
    -- Options to be merged with the parent specification
    opts = { use_diagnostic_signs = true }, -- Use diagnostic signs for trouble.nvim
  },

  -- Add symbols-outline.nvim plugin
  {
    -- Plugin: symbols-outline.nvim
    -- URL: https://github.com/simrat39/symbols-outline.nvim
    -- Description: A tree like view for symbols in Neovim using the Language Server Protocol.
    "simrat39/symbols-outline.nvim",
    cmd = "SymbolsOutline", -- Command to open the symbols outline
    keys = {
      { "<leader>cs", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" },
    }, -- Keybinding to open the symbols outline
    config = true, -- Use default configuration
  },
  -- Add gitsigns.nvim plugin
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      return opts
    end,
    keys = {
      {
        "<leader>gp",
        "<cmd>Gitsigns preview_hunk<CR>",
        desc = "Git Preview Hunk",
      },
      {
        "<leader>gt",
        "<cmd>Gitsigns toggle_current_line_blame<CR>",
        desc = "Git Toggle Blame",
      },
    },
  },
  -- Add which-key.nvim plugin
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      opts.window = { border = "none", position = "bottom" }
      opts.layout = {
        height = { min = 4, max = 25 },
        width = { min = 30, max = 30 },
        spacing = 8,
        align = "left",
      }
      return opts
    end,
    keys = {
      {
        "<leader>o",
        "<cmd>lua require('oil').toggle_float()<CR>",
        desc = "oil (cwd)",
      },
    },
  },
}
