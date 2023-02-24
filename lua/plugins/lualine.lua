local theme = require('plugins.theme')
theme_plugin = theme.name and theme.name or theme[1]
local M = {
  "nvim-lualine/lualine.nvim",
  dependencies = { 
    "hek14/nvim-navic",
    "nvim-lua/lsp-status.nvim",
    "hek14/vim-illuminate",
    "nvim-tree/nvim-web-devicons",
    theme_plugin
  },
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

local reference_hint = function ()
  local buf = vim.api.nvim_get_current_buf()
  local ok,illuminate = require('illuminate')
  if not ok then
    return ""
  else
    local refs = _G.illuminate_references[buf]
    local current_loc = nil
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local current_col = vim.api.nvim_win_get_cursor(0)[2]
    for i,ref in ipairs(refs) do
      local _start = ref.range.start
      local _end = ref.range['end']
      local condition = _start.line+1 == current_line and
      _start.character <= current_col and
      _end.line+1 >= current_line and
      _end.character >= current_col
      if condition then
        current_loc = i
        break
      end
    end
    return string.format("%d|%d",current_loc,#refs)
  end
end

local function pwd()
  local win = vim.api.nvim_get_current_win()
  local path = vim.fn.getcwd(win)
  path =  string.gsub(path,vim.env['HOME'],'~')
  if path=='~' then
    return "HOME"
  else
    return path
  end
end

vim.opt.laststatus = 3
M.config = function ()
  require('lualine').setup {
    options = {
      globalstatus = true,
      theme = 'auto'    
    },
    winbar = {},
    inactive_winbar = {},
    sections = {
      lualine_a = {'mode'},
      lualine_b = {'branch', 'diff', 'diagnostics'},
      lualine_c = { 
        { 
          pwd, 
          icon = ':Dir:',
          color = { fg='#8caaee', bg='#51576d' }
        }
      },
      lualine_x = {
        {
          reference_hint,
          icon = ' Reference:',
          color = { fg='#8caaee', bg='#51576d' }
        },
      },
      lualine_y = {'filetype'},
      lualine_z = {'progress'}
    },
    inactive_sections = {},
  }  
end

return M
