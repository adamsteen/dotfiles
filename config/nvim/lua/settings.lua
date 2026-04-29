-- basic settings
vim.o.encoding = "utf-8"

-- Sidebar
vim.o.number = true -- line number on the left

-- Search
vim.o.hlsearch = false -- turns of highlighting of search hits
vim.o.incsearch = true -- starts searching as soon as typing, without enter needed
vim.o.ignorecase = true -- ignore letter case when searching
vim.o.smartcase = true -- case insentive unless capitals used in search

-- Colour Scheme
vim.g.base16colorspace = 256
vim.opt.termguicolors = true
vim.cmd('colorscheme base16-default-dark')

vim.wo.colorcolumn = '80'

-- toggle invisible characters
vim.opt.list = true
vim.opt.listchars = {
  tab = ">-",
  trail = ".",
}

-- Backup files (cross-platform: uses stdpath instead of hardcoded paths)
local config_dir = vim.fn.stdpath('config')
vim.o.undofile = true
vim.o.backup = true
vim.o.writebackup = true
vim.o.swapfile = true
vim.o.undodir = config_dir .. '/undo/'
vim.o.backupdir = config_dir .. '/backup/'
vim.o.directory = config_dir .. '/backup/'
vim.o.undolevels=1000                      -- number of undos
vim.o.undoreload=10000                     -- number of lines to save for undo

-- White characters
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.tabstop = 2 -- 1 tab = 2 spaces
vim.o.shiftwidth = 2 -- indentation rule
vim.o.expandtab = true -- expand tab to spaces

vim.g.ale_fix_on_save = 1
