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
      top = "PIG:🐷",
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
        if i_range.start.line == j_range.start.line then
          return i_range.start.character < j_range.start.character
        else
          return i_range.start.line < j_range.start.line
        end
      else
        return true
      end
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
  local location_id = 0
  for i,group in ipairs(groups) do
    local file_name = fn.fnamemodify(vim.uri_to_fname(group[1]),':~:.')
    table.insert(menus,Menu.separator(file_name,{text_align = "left"}))
    total_lines = total_lines + 1
    for i = 2, #group do
      local loc = group[i]
      local item = lsp.util.locations_to_items({loc})[1]
      local range = loc.range or loc.targetSelectionRange
      location_id = location_id + 1
      table.insert(menus,Menu.separator("location " .. location_id, {text_align = "left"}))
      total_lines = total_lines + 1
      for k = -ctx_lines,ctx_lines do
        ---- NOTE: any lines in the same context block refer to the same location
        local ctx_loc = Inc_loc(loc,k)
        local ctx_item = lsp.util.locations_to_items({ctx_loc})[1]
        -- local _range = _loc.range or _loc.targetSelectionRange
        -- table.insert(menus,Menu.item(_item.text, {loc=_loc,item=_item}))
        total_lines = total_lines + 1
        table.insert(menus,Menu.item(ctx_item.text, {loc=loc,item=item,is_ref=k==0,line=total_lines-k,col=range.start.character}))
      end
    end
  end
  return menus
end

local function builtin_preview_handler(label, result, ctx, config)
  local locations = vim.tbl_islist(result) and result or {result}
  vim.lsp.util.preview_location(locations[1])
end

function _goto_next_loc_in_menu(index)
  local nodes = _G.PIG_menu._tree:get_nodes()
  local length = #nodes
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]

  local result = nil
  if index < 0 then
    Start = length
    End = 1
    Step = -1
  else
    Start = 1
    End = length
    Step = 1
  end
  local first_ref_node = nil
  local last_ref_node  = nil
  for i = Start,End,Step do
    local node = nodes[i]
    if node.is_ref then
      if index > 0 then
        if not first_ref_node then
          first_ref_node = node
        end
        if node.line > current_line then
          result = node
          break
        elseif node.line == current_line and node.col > current_col then
          result = node
          break
        end
      else
        if not last_ref_node then
          last_ref_node = node
        end
        if node.line < current_line then
          result = node
          break
        elseif node.line == current_line and node.col < current_col then
          result = node
          break
        end
      end
    end
  end
  if result == nil then
    if index > 0 then
      result = first_ref_node
    else
      result = last_ref_node
    end
  end
  P('jump to next loc: ',result.line,result.col)
  vim.api.nvim_win_set_cursor(0, {result.line, result.col})
  return result
end

function _goto_next_file_in_menu(index)
  local nodes = _G.PIG_menu._tree:get_nodes()
  local length = #nodes
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_node = _G.PIG_menu._tree:get_node(current_line)
  while not current_node.loc do
    current_line = current_line + 1
    current_node = _G.PIG_menu._tree:get_node(current_line)
  end
  current_uri = current_node.loc.uri or current_node.loc.targetUri

  local result = nil
  if index < 0 then
    Start = current_line - 1
    End = 1
    Step = -1
  else
    Start = current_line + 1
    End = length
    Step = 1
  end
  for i = 1,length,1 do
    if nodes[i].is_ref then
      first_ref_node = nodes[i]
      break
    end
  end
  for i = length,1,-1 do
    if nodes[i].is_ref then
      last_ref_node = nodes[i]
      break
    end
  end
  for i = Start,End,Step do
    local node = nodes[i]
    if node.is_ref then
      node_uri = node.loc.uri or node.loc.targetUri
      if node_uri~=current_uri then
        result = node
        break
      end
    end
  end
  if result == nil then
    if index > 0 then
      result = first_ref_node
    else
      result = last_ref_node
    end
  end
  P('jump to next loc: ',result.line,result.col)
  vim.api.nvim_win_set_cursor(0, {result.line, result.col})
  return result
end

local function location_handler(label, result, ctx, config)
  local ft = vim.api.nvim_buf_get_option(ctx.bufnr, 'ft')
  local locations = vim.tbl_islist(result) and result or {result}
  local sorted_locations = sort_locations(locations)
  local groups = group_by_uri(sorted_locations)
  local menus = make_menu(groups)
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
        print("PIG CLOSED")
      end,
      on_change = function(node,menu)
        _G.PIG_node = node
        _G.PIG_loc = node.loc
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
  _G.PIG_menu = menu
  vim.api.nvim_buf_call(menu.bufnr,function ()
    _goto_next_loc_in_menu(1)
  end)
  vim.api.nvim_buf_set_option(menu.bufnr,"ft",ft)
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","]]",":lua _goto_next_loc_in_menu(1)<CR>",{noremap=true})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","[[",":lua _goto_next_loc_in_menu(-1)<CR>",{noremap=true})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","]f",":lua _goto_next_file_in_menu(1)<CR>",{noremap=true})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","[f",":lua _goto_next_file_in_menu(-1)<CR>",{noremap=true})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","<leader>s",":silent lua PIG_menu.menu_props.on_close()<CR>:silent sp<CR>:silent lua vim.lsp.util.jump_to_location(PIG_loc)<CR>",{noremap=true})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","<leader>v",":silent lua PIG_menu.menu_props.on_close()<CR>:silent vsp<CR>:silent lua vim.lsp.util.jump_to_location(PIG_loc)<CR>",{noremap=true})
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

local handlers = {
  ['textDocument/definition'] = {label = 'Definitions', target = location_handler},
  ['textDocument/references'] = {label = 'References', target = location_handler}
}

local M = {}

M.setup_handler = function ()
  for k,v in pairs(handlers) do
    vim.lsp.handlers[k] = wrap_handler(v)
  end
end

M.async_ref = function ()
  local ref_params = vim.lsp.util.make_position_params()
  ref_params.context = { includeDeclaration = false }
  vim.lsp.buf_request(0,'textDocument/references', ref_params, wrap_handler{label = 'References', target = location_handler})
end

M.async_def = function ()
  local ref_params = vim.lsp.util.make_position_params()
  ref_params.context = { includeDeclaration = false }
  vim.lsp.buf_request(0,'textDocument/definition', ref_params, wrap_handler{label = 'Definitions', target = location_handler})
end

M.async_typedef = function ()
  local ref_params = vim.lsp.util.make_position_params()
  ref_params.context = { includeDeclaration = false }
  vim.lsp.buf_request(0,'textDocument/typeDefinition', ref_params, wrap_handler{label = 'TypeDefinitions', target = location_handler})
end

M.async_declare = function ()
  local ref_params = vim.lsp.util.make_position_params()
  ref_params.context = { includeDeclaration = false }
  vim.lsp.buf_request(0,'textDocument/declaration', ref_params, wrap_handler{label = 'Declarations', target = location_handler})
end

M.async_implement = function ()
  local ref_params = vim.lsp.util.make_position_params()
  ref_params.context = { includeDeclaration = false }
  vim.lsp.buf_request(0,'textDocument/implementation', ref_params, wrap_handler{label = 'Implementations', target = location_handler})
end

return M
