vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.mouse = "a"
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.scrolloff = 6
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400

local nvim_tools = vim.fn.stdpath("data") .. "/tools/node_modules/.bin"
if vim.uv.fs_stat(nvim_tools) then vim.env.PATH = nvim_tools .. ":" .. vim.env.PATH end

local lazy = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazy) then
  vim.notify("Run make install in your dotfiles checkout to install the editor plugins.", vim.log.levels.WARN)
  return
end
vim.opt.rtp:prepend(lazy)

require("lazy").setup({
  { "rose-pine/neovim", name = "rose-pine", priority = 1000, config = function()
    require("rose-pine").setup({ variant = "main", dark_variant = "main" })
    vim.cmd.colorscheme("rose-pine")
  end },
  { "stevearc/oil.nvim", opts = { columns = { "permissions", "size" }, view_options = { show_hidden = true } } },
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" }, opts = {} },
  { "nvim-lualine/lualine.nvim", opts = { options = { theme = "rose-pine", icons_enabled = false } } },
  { "lewis6991/gitsigns.nvim", opts = {} },
  { "nvim-mini/mini.nvim", config = function()
    require("mini.ai").setup()
    require("mini.pairs").setup()
    require("mini.surround").setup()
    require("mini.starter").setup()
  end },
  { "saghen/blink.cmp", version = "v1.10.2", opts = {
    keymap = { preset = "default" },
    fuzzy = { implementation = "lua" },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
  } },
  { "neovim/nvim-lspconfig", dependencies = { "saghen/blink.cmp", "b0o/SchemaStore.nvim" }, config = function()
    vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
    local schemastore = require("schemastore")
    vim.lsp.config("yamlls", { settings = { yaml = { schemas = schemastore.yaml.schemas() } } })
    vim.lsp.config("jsonls", { settings = { json = { schemas = schemastore.json.schemas() } } })
    -- Only enable servers whose executables are installed.
    for server, command in pairs({ bashls = "bash-language-server", lua_ls = "lua-language-server", yamlls = "yaml-language-server", jsonls = "vscode-json-language-server" }) do
      if vim.fn.executable(command) == 1 then vim.lsp.enable(server) end
    end
  end },
  { "stevearc/conform.nvim", opts = {
    formatters_by_ft = { sh = { "shfmt" }, lua = { "stylua" } },
  } },
}, {
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  checker = { enabled = false },
  change_detection = { notify = false },
  headless = { process = false, task = false, log = true, colors = false },
})

local map = vim.keymap.set
map("n", "-", "<cmd>Oil<cr>", { desc = "Browse this directory" })
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Search text" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })
map("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>", { desc = "Find diagnostics" })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "K", vim.lsp.buf.hover, { desc = "Documentation" })
map("n", "<leader>f", function() require("conform").format({ lsp_format = "fallback" }) end, { desc = "Format buffer" })
map("n", "<esc>", "<cmd>nohlsearch<cr>")
vim.diagnostic.config({ virtual_text = true, severity_sort = true })

local local_config = vim.fn.expand("~/.config/nvim-local.lua")
if vim.uv.fs_stat(local_config) then dofile(local_config) end
