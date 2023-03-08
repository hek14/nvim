local theme = require('plugins.theme')
local theme_plugin = theme.name and theme.name or theme[1]
local M = {
  "nvim-lualine/lualine.nvim",
  dependencies = { 
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

local total_ref 
local current_loc
local current_tick

local reference_hint = function ()
  local buf = vim.api.nvim_get_current_buf()
  if not package.loaded['illuminate'] then
    return ""
  else
    local refs = _G.illuminate_references[buf]
    if current_tick~=_G.illuminate_update_tick[buf] then
      total_ref = #refs
      current_tick = _G.illuminate_update_tick[buf]
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
      if current_loc == nil then
        current_loc = 'ERR'
      end
    end
    return string.format("%d|%d",current_loc,total_ref)
  end
end

local lsp_name = function ()
  local clients = any_client_attached() 
  local names = ""
  for _,client in ipairs(clients) do
    names = names .. client.name .. "|"
  end
  names = string.sub(names,1,#names-1)
  return names
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
M.highlight = function ()
  local modes = {'normal','visual','insert','command'}
  local things = {"","diagnostics_info","diagnostics_hint","diagnostics_warn"}
  for _,thing in ipairs(things) do
    for _,m in ipairs(modes) do
      local src = #thing==0 and ('lualine_c_' .. m) or ('lualine_c_' .. thing .. '_' .. m)
      local tar = #thing==0 and ('lualine_b_' .. m) or ('lualine_b_' .. thing .. '_' .. m)
      vim.api.nvim_set_hl(0,src,{link = tar})
    end
  end
  vim.api.nvim_set_hl(0,"lualine_c_diagnostics_error_normal", { fg = '#f14c4c', bg = '#007acc' })
end
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
      lualine_b = { 
        { 
          pwd, 
          icon = ':Dir:',
          color = { fg='#8caaee', bg='#51576d' }
        }
      },
      lualine_c = {'branch', 'diagnostics'},
      lualine_x = {
        {
          reference_hint,
          icon = ' Reference:',
          color = { fg='#8caaee', bg='#51576d' }
        },
        {
          lsp_name,
          icon = ' LSP:',
          color = { fg='#8caaee', bg='#51576d' }
        },
      },
      lualine_y = {'filetype'},
      lualine_z = {'location'}
    },
    inactive_sections = {},
  }  
  M.highlight()
end

return M
