local M = {
  "nvim-lualine/lualine.nvim",
  enabled = false,
  dependencies = { "hek14/nvim-navic","hek14/vim-illuminate","nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
}

local winbar = function ()
  local navic = require('nvim-navic') 
  local filename = vim.fn.expand('%:t')
  if navic.is_available() then
    local loc = navic.get_location()
    if loc=="" then
      return filename
    else
      return filename .. ' > ' .. loc
    end
  else
    return filename
  end
end

local inactive_winbar = function ()
  local filename = vim.fn.expand('%:p')
  local home = vim.fn.expand("$HOME") .. '/'
  filename = string.gsub(filename, home, '')
  return filename
end

vim.opt.laststatus = 3
M.config = function ()
  require('lualine').setup {
    options = {
      globalstatus = true,
    },
    winbar = {
      lualine_a = { winbar },
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = {}
    },
    inactive_winbar = {
      lualine_a = { inactive_winbar }
    },
    sections = {
      lualine_a = {'mode'},
      lualine_b = {'branch', 'diff', 'diagnostics'},
      lualine_c = {},
      lualine_x = {
        {
          'buffers',
          show_modified_status = true, -- Shows indicator when the buffer is modified.
          mode = 4,
          -- 0: Shows buffer name
          -- 1: Shows buffer index
          -- 2: Shows buffer name + buffer index
          -- 3: Shows buffer number
          -- 4: Shows buffer name + buffer number
          max_length = vim.o.columns * 2 / 3, -- Maximum width of buffers component,
          -- it can also be a function that returns
          -- the value of `max_length` dynamically.
          symbols = {
            modified = ' ●',      -- Text to show when the buffer is modified
            alternate_file = '#', -- Text to show to identify the alternate file
            directory =  '',     -- Text to show when the buffer is a directory
          },
        }
      },
      lualine_y = {'filetype'},
      lualine_z = {'progress'}
    },
    inactive_sections = {},
  }  
end

return M
