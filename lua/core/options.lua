local opt = vim.opt
local g = vim.g

local os_name = vim.loop.os_uname().sysname
_G.is_mac = os_name == 'Darwin'
_G.is_linux = os_name == 'Linux'
_G.is_windows = os_name == 'Windows'
_G.diagnostic_choice = "telescope" -- telescope or Trouble

local clippy_found = vim.fn.executable("clippy")==1

opt.title = true
opt.clipboard = clippy_found and "unnamedplus" or ""
g.clipboard = {
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

opt.cmdheight = 1
opt.cul = true -- cursor line

-- Indentline
opt.expandtab = true
opt.shiftwidth = 2
opt.smartindent = true

-- disable tilde on end of buffer: https://github.com/neovim/neovim/pull/8546#issuecomment-643643758
opt.fillchars = { eob = " " }

opt.hidden = true
opt.ignorecase = true
opt.smartcase = true
opt.mouse = "a"

-- Numbers
opt.number = true
opt.relativenumber = true
opt.numberwidth = 2
opt.ruler = false

-- disable nvim intro
opt.shortmess:append "sI"

opt.signcolumn = "yes"
opt.splitbelow = true
opt.splitright = true
opt.tabstop = 8
opt.termguicolors = true
opt.timeoutlen = 400
opt.undofile = true

opt.listchars:append("space:⋅")
opt.listchars:append("eol:↴")
opt.listchars:append("tab:↹ ")

-- interval for writing swap file to disk, also used by gitsigns
opt.updatetime = 200

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
opt.whichwrap:append "<>[]hl"

-- indent: needed by ufo
-- opt.foldcolumn = '1'
opt.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
opt.foldlevelstart = -1
opt.foldenable = true

g.mapleader = " "


--Defer loading shada until after startup_
local backup_shadafile = vim.opt.shadafile
vim.opt.shadafile = "NONE"


vim.schedule(function()
   vim.opt.shadafile = backup_shadafile
   vim.cmd [[ silent! rsh ]]
end)

vim.cmd [[set viminfo+=:2000]]
vim.env['PATH'] = vim.fn.stdpath('config') .. '/bin:' .. vim.env['PATH']
