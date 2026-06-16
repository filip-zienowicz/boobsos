-- ==============================================
-- BOOTSTRAP LAZY.NVIM
-- ==============================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- ==============================================
-- OPCJE EDYTORA
-- ==============================================
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.g.mapleader = " "

-- Kopiowanie z Neovima na zdalnym serwerze do lokalnego schowka Maca.
-- Dziala przez SSH w terminalach obslugujacych OSC52 (np. iTerm2, WezTerm, Kitty,
-- nowszy Terminal.app). Cmd+C zostaje po stronie terminala, a y/yank kopiuje do Maca.
local function osc52_copy(lines, _)
  local text = table.concat(lines, '\n')
  local encoded = vim.fn.system('base64 -w 0', text):gsub('%s+', '')
  io.stderr:write('\027]52;c;' .. encoded .. '\007')
  io.stderr:flush()
end

local function clipboard_paste()
  return { vim.fn.split(vim.fn.getreg('"'), '\n'), vim.fn.getregtype('"') }
end

vim.g.clipboard = {
  name = 'OSC52',
  copy = {
    ['+'] = osc52_copy,
    ['*'] = osc52_copy,
  },
  paste = {
    ['+'] = clipboard_paste,
    ['*'] = clipboard_paste,
  },
}
vim.opt.clipboard = 'unnamedplus'

vim.opt.mouse = ''

-- ==============================================
-- PLUGINY
-- ==============================================
require("lazy").setup({
  { "folke/tokyonight.nvim", lazy = false, priority = 1000 },
  { "nvim-lualine/lualine.nvim" },
  { "nvim-treesitter/nvim-treesitter", branch = "master", build = ":TSUpdate" },
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "neovim/nvim-lspconfig" },

  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
  { "rafamadriz/friendly-snippets" },

  { "numToStr/Comment.nvim" },
  { "windwp/nvim-autopairs" },
  { "lewis6991/gitsigns.nvim" },
})

vim.cmd[[colorscheme tokyonight]]
require('lualine').setup()
require('nvim-tree').setup()
require('Comment').setup()
require('nvim-autopairs').setup()
require('gitsigns').setup()

require('nvim-treesitter.configs').setup({
  ensure_installed = {
    "lua", "vim", "vimdoc", "bash", "python", "javascript", "typescript",
    "tsx", "html", "css", "json", "yaml", "markdown", "dockerfile", "go", "rust"
  },
  highlight = { enable = true },
  indent = { enable = true },
})

require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = {
    "lua_ls", "bashls", "pyright", "ts_ls",
    "html", "cssls", "jsonls", "yamlls", "dockerls",
  },
})

-- Nowy API (nvim 0.11+): vim.lsp.config + LspAttach autocmd.
-- Mason-lspconfig 2.0 sam wywoła vim.lsp.enable() dla każdego z ensure_installed.
local capabilities = require('cmp_nvim_lsp').default_capabilities()
vim.lsp.config('*', { capabilities = capabilities })

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'K',  vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>f',  function() vim.lsp.buf.format({ async = true }) end, opts)
    vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
    vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
    vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)
  end,
})

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

local cmp = require('cmp')
local luasnip = require('luasnip')
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>']      = cmp.mapping.confirm({ select = true }),
    ['<Tab>']     = cmp.mapping.select_next_item(),
    ['<S-Tab>']   = cmp.mapping.select_prev_item(),
    ['<C-d>']     = cmp.mapping.scroll_docs(4),
    ['<C-u>']     = cmp.mapping.scroll_docs(-4),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' },
  }),
})

vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>',           { desc = 'Drzewo plików' })
vim.keymap.set('n', '<C-p>',     ':Telescope find_files<CR>',     { desc = 'Szukaj pliku (Ctrl+P)' })
vim.keymap.set('n', '<leader>g', ':Telescope live_grep<CR>',      { desc = 'Szukaj w plikach' })
vim.keymap.set('n', '<leader>b', ':Telescope buffers<CR>',        { desc = 'Otwarte bufory' })
vim.keymap.set('v', '<C-c>', '"+y',                               { desc = 'Kopiuj zaznaczenie do schowka Maca' })
vim.keymap.set({'n', 'v'}, '<leader>y', '"+y',                    { desc = 'Kopiuj do schowka Maca' })
vim.keymap.set('n', '<leader>Y', 'gg"+yG',                        { desc = 'Kopiuj cały plik do schowka Maca' })

vim.keymap.set('n', '<leader>m', function()
  if vim.opt.mouse:get() == '' then
    vim.opt.mouse = 'a'
    print('Mouse: ON')
  else
    vim.opt.mouse = ''
    print('Mouse: OFF')
  end
end, { desc = 'Toggle mouse' })
