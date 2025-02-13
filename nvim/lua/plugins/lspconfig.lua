return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -------------------------------
      -- 1. Ensure servers are installed
      -------------------------------
      opts.ensure_installed = opts.ensure_installed or {}

      local function ensure_installed(server)
        if not vim.tbl_contains(opts.ensure_installed, server) then
          table.insert(opts.ensure_installed, server)
        end
      end

      -- Add Swift support (sourcekit) and make sure TypeScript is installed.
      ensure_installed("sourcekit")
      ensure_installed("ts_ls")
      -- 2. Merge additional server settings
      -------------------------------
      -- Merge your custom server options with any defaults.
      opts.servers = vim.tbl_deep_extend("force", opts.servers or {}, {
        -- Customize the SourceKit LSP (for Swift/Objective‑C)
        sourcekit = {
          -- Uncomment and adjust the following if you need to override
          -- the default command or other settings:
          capabilities = capabilities,
          on_attach = on_attach,
          cmd = lsp == "sourcekit" and { vim.trim(vim.fn.system("xcrun -f sourcekit-lsp")) } or nil,
          filetypes = { "swift", "objc", "objective-c" },
          --
          -- You can add additional options as needed.
        },
        -- Customize typescript LSP (for JS/TS/JSX/TSX)
        -- ts_ls = {
        --   cmd = { "typescript-language-server", "--stdio" },
        --   filetypes = {
        --     "javascript",
        --     "javascriptreact",
        --     "javascript.jsx",
        --     "typescript",
        --     "typescriptreact",
        --     "typescript.tsx",
        --   },
        --   root_dir = util.root_pattern("tsconfig.json", "jsconfig.json", "package.json", ".git"),
        --   single_file_support = true,
        -- },
      })

      -------------------------------
      -- 3. (Optional) Merge custom handlers
      -------------------------------
      -- If you want to provide a custom handler for sourcekit you can do so here.
      -- (If you leave it out, the default handler from LazyVim remains in effect.)
      opts.handlers = vim.tbl_deep_extend("force", opts.handlers or {}, {
        sourcekit = function()
          require("lspconfig").sourcekit.setup({
            capabilities = opts.capabilities,
            -- Add any additional SourceKit-specific options here.
          })
        end,
      })

      return opts
    end,
  },
}
