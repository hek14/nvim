local api, cmd, fn, g, vim = vim.api, vim.cmd, vim.fn, vim.g, vim
local lsp = require 'vim.lsp'
local fmt = string.format
local current_actions = {}  -- hold all currently available code actions
local last_results = {}     -- hold last location results
local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event

local popup_options = {
  relative = "cursor",
  position = {
    row = 1,
    col = 0,
  },
  border = {
    style = "rounded",
    text = {
      top = "Peek Definition by KK",
      top_align = "center",
    },
  },
  win_options = {
    winhighlight = "Normal:Normal",
  }
}

local function echo(hlgroup, msg)
  cmd(fmt('echohl %s', hlgroup))
  cmd(fmt('echo "[lspconfig] %s"', msg))
  cmd('echohl None')
end

local sort_locations = function(locations)
  table.sort(locations, function(i, j)
    local i_uri = i.uri or i.targetUri
    local j_uri = j.uri or j.targetUri
    if i_uri == j_uri then
      local i_range = i.range or i.targetRange
      local j_range = j.range or j.targetRange
      if i_range and i_range.start then
        return i_range.start.line < j_range.start.line
      end
      return false
    else
      return i_uri < j_uri
    end
  end)
  return locations
end

local group_by_uri = function(locations)
  local current = nil
  local groups = {}
  for i,loc in ipairs(locations) do
    local uri = loc.uri or loc.targetUri
    if uri ~= current then
      table.insert(groups,{uri,loc})
      current = uri
    else
      table.insert(groups[#groups],loc)
    end
  end
  return groups
end
-- location and item looks like below:
-- "location" {
--   originSelectionRange = {
--     end = {
--       character = 14,
--       line = 103
--     },
--     start = {
--       character = 9,
--       line = 103
--     }
--   },
--   targetRange = {
--     end = {
--       character = 13,
--       line = 90
--     },
--     start = {
--       character = 8,
--       line = 90
--     }
--   },
--   targetSelectionRange = {
--     end = {
--       character = 13,
--       line = 90
--     },
--     start = {
--       character = 8,
--       line = 90
--     }
--   },
--   targetUri = "file:///home/heke/.config/nvim/contrib/my_lsp_handler.lua"
-- }
--
-- "item" {
--   col = 9,
--   filename = "/home/heke/.config/nvim/contrib/my_lsp_handler.lua",
--   lnum = 91,
--   text = "  local menus = {}"
-- }
--

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local Inc_loc = function(loc,index)
  local new_loc = deepcopy(loc)
  if loc.targetSelectionRange then
    new_loc.targetSelectionRange = {
      ['end'] = {
        character = loc.targetSelectionRange['end'].character,
        line = loc.targetSelectionRange['end'].line + index
      },
      ['start'] = {
        character = loc.targetSelectionRange['start'].character,
        line = loc.targetSelectionRange['start'].line + index
      }
    }
  elseif loc.range then
    new_loc.range = {
      ['end'] = {
        character = loc.range['end'].character,
        line = loc.range['end'].line + index
      },
      ['start'] = {
        character = loc.range['start'].character,
        line = loc.range['start'].line + index
      }
    }
  else
    new_loc = nil
    echo("ErrorMsg","loc nil" .. vim.inspect(loc))
  end
  return new_loc
end

local make_menu = function(groups)
  -- groups: seperated by files
  local menus = {}
  local ctx_lines = 1 -- lines of context
  local total_lines = 0
  local menu_locs = {}
  for i,group in ipairs(groups) do
    local file_name = fn.fnamemodify(vim.uri_to_fname(group[1]),':~:.')
    table.insert(menus,Menu.separator(file_name))
    total_lines = total_lines + 1
    for i = 2, #group do
      local loc = group[i]
      local item = lsp.util.locations_to_items({loc})[1]
      table.insert(menus,Menu.separator("location " .. i-1))
      total_lines = total_lines + 1
      for k = -ctx_lines,ctx_lines do
        local _loc = Inc_loc(loc,k)
        local _item = lsp.util.locations_to_items({_loc})[1]
        local _range = _loc.range or _loc.targetSelectionRange
        -- P("k",k,"current _loc",_loc.targetSelectionRange.start.line)
        table.insert(menus,Menu.item(_item.text, {loc=_loc,item=_item}))
        total_lines = total_lines + 1
        if k==0 then
          table.insert(menu_locs,{line=total_lines,col=_range.start.character})
        end
      end
    end
  end
  table.sort(menu_locs,function(i,j)
    if i.line == j.line then
      return i.col < j.col
    else
      return i.line < j.line
    end
  end)
  return menus,menu_locs
end

local function builtin_preview_handler(label, result, ctx, config)
  local locations = vim.tbl_islist(result) and result or {result}
  vim.lsp.util.preview_location(locations[1])
end

function _goto_next_loc_in_menu(index)
  local locs = _G._menu_locs
  local current = vim.api.nvim_win_get_cursor(0)
  local result = nil
  if index < 0 then
    Start = #locs
    End = 1
    Step = -1
  else
    Start = 1
    End = #locs
    Step = 1
  end
  for i = Start,End,Step do
    local loc = locs[i]
    if index > 0 then
      if loc.line > current[1] then
        result = loc
        break
      elseif loc.line == current[1] and loc.col > current[2] then
        result = loc
        break
      end
    else
      if loc.line < current[1] then
        result = loc
        break
      elseif loc.line == current[1] and loc.col < current[2] then
        result = loc
        break
      end
    end
  end
  if result == nil then
    if index > 0 then
      result = locs[1]
    else
      result = locs[#locs]
    end
  end
  vim.api.nvim_win_set_cursor(0, {result.line, result.col})
  return result
end

local function location_handler(label, result, ctx, config)
  local ft = vim.api.nvim_buf_get_option(ctx.bufnr, 'ft')
  local locations = vim.tbl_islist(result) and result or {result}
  local sorted_locations = sort_locations(locations)
  local groups = group_by_uri(sorted_locations)
  -- items = lsp.util.locations_to_items(locations)
  local menus,menu_locs = make_menu(groups)
  _G._menu_locs = menu_locs
  local menu = Menu(
    popup_options,
    {
      lines = menus,
      min_width = 40,
      keymap = {
        focus_next = { "n", "<Down>", "<Tab>" },
        focus_prev = { "e", "<Up>", "<S-Tab>" },
        close =  { "<Esc>", "<C-c>" },
        submit = { "<CR>", "<Space>" },
      },
      on_close = function()
        print("CLOSED")
      end,
      on_submit = function(item)
        local loc = item.loc
        if loc then
          lsp.util.jump_to_location(loc)
        else
          echo('ErrorMsg', "can't jump to location")
        end
      end,
    }
  )
  menu:mount()
  vim.api.nvim_buf_call(menu.bufnr,function ()
    _goto_next_loc_in_menu(1)
  end)
  vim.api.nvim_buf_set_option(menu.bufnr,"ft",ft)
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","k",":lua _goto_next_loc_in_menu(1)<CR>",{noremap=true})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","K",":lua _goto_next_loc_in_menu(-1)<CR>",{noremap=true})
end

local function wrap_handler(handler)
  local wrapper = function(err, result, ctx, config)
    if err then
      return echo('ErrorMsg', err.message)
    end

    if not result or vim.tbl_isempty(result) then
      return echo('ErrorMsg', fmt('No %s found', string.lower(handler.label)))
    end

    return handler.target(handler.label, result, ctx, config)
  end

  -- See neovim#15504
  if fn.has('nvim-0.5.1') == 0 then
    return function(err, method, result, client_id, bufnr, config)
      local ctx = {method = method, client_id = client_id, bufnr = bufnr}
      return wrapper(err, result, ctx, config)
    end
  end

  return wrapper
end

local handlers = {['textDocument/definition'] = {label = 'Definitions', target = location_handler}}

local M = {}
M.setup = function ()
  lsp.handlers['textDocument/definition'] = wrap_handler(handlers['textDocument/definition'])
  -- you can compare mine with the built-in preview location
  -- lsp.handlers['textDocument/definition'] = wrap_handler({label = "Builtin Definition", target = builtin_preview_handler})
end
return M
