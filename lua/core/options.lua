_G.os_name = vim.loop.os_uname().sysname
_G.is_mac = os_name == 'Darwin'
_G.is_linux = os_name == 'Linux'
_G.is_windows = os_name == 'Windows'

vim.g.mapleader = " "
vim.g.maplocalleader = ','

vim.opt.laststatus = 3
vim.opt.showmode = false
vim.opt.title = true

local use_clippy = false
if vim.fn.executable("clippy")==1 and use_clippy then
  vim.opt.clipboard = "unnamedplus"
  vim.g.clipboard = {
    name = 'ClippyRemoteClipboard',
    copy = {
      ['+'] = 'clippy set',
      ['*'] = 'clippy set',
    },
    paste= {
      ['+'] = 'clippy get',
      ['*'] = 'clippy get',
    },
    cache_enabled= 0,
  }
end

vim.opt.cmdheight = 1
vim.opt.cul = true -- cursor line

-- Indentline
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.smartindent = true

-- disable tilde on end of buffer: https://github.com/neovim/neovim/pull/8546#issuecomment-643643758
vim.opt.fillchars = { eob = " " }

vim.opt.hidden = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.mouse = "a"

-- Numbers
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.numberwidth = 2
vim.opt.ruler = false

-- disable nvim intro
vim.opt.shortmess:append "sI"
vim.opt.shortmess:append "c"

vim.opt.signcolumn = "yes"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.tabstop = 8
vim.opt.termguicolors = true
vim.opt.timeoutlen = 400
vim.opt.undofile = true

-- interval for writing swap file to disk, also used by gitsigns
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
vim.opt.whichwrap:append "<>[]hl"

-- wrap to `textwidth`
vim.opt.wrap = false

-- indent: needed by ufo
-- opt.foldcolumn = '1'
vim.opt.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.opt.foldlevelstart = -1
vim.opt.foldenable = true
vim.opt.foldmethod = 'indent'
vim.opt.foldexpr = nil

-- for nvim-cmp
vim.opt.completeopt = { "menu", "menuone", "noselect" }

vim.opt.list = true
vim.opt.listchars = {
    -- leadmultispace = "┊ ",
    leadmultispace = "  ",
    trail = "␣",
    nbsp = "⍽",
    -- space = "⋅",
}
-- or use append
vim.opt.listchars:append("eol:↴")
vim.opt.listchars:append("tab:↹ ")

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

vim.opt.hlsearch = true

vim.env['PATH'] = vim.fn.stdpath('config') .. '/bin:' .. vim.env['PATH']
