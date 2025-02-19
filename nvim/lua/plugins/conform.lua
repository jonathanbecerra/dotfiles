return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft =
        vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
          swift = { "swiftformat" },
        })

      -- opts.format_on_save = function(bufnr)
      --   local ignore_filetypes = { "oil" }
      --   if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
      --     return
      --   end
      --   return { timeout_ms = 500, lsp_fallback = true }
      -- end

      opts.log_level = vim.log.levels.ERROR

      return opts
    end,
  },
}
