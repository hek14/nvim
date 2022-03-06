local api, cmd, fn, g, vim = vim.api, vim.cmd, vim.fn, vim.g, vim
local lsp = require 'vim.lsp'
local fmt = string.format
local current_actions = {}  -- hold all currently available code actions
local last_results = {}     -- hold last location results
local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event

local M = {}
-- serve as a lock
_G.PIG_state = {
  References = "init",
  Definitions = "init",
  TypeDefinitions = "init",
  Declarations = "init",
  Implementations = "init",
  NextReference = "init",
  Refactor = "init",
}

local function PIG_in_progress()
  local in_progress = false
  for k,v in pairs(_G.PIG_state) do
    if v=="in_progress" then
      in_progress = true
      break
    end
  end
  return in_progress
end

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
  cmd(fmt('echo "[PIG] %s"', msg))
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

deep_equal = function(t1,t2)
  for i = 1,#t1 do
    if type(t1[i]) == "table" then
      if type(t2[i]) ~= "table" then return false end
      if not deep_equal(t1[i],t2[i]) then
        return false
      end
    else
      if t1[i]~=t2[i] then return false end
    end
  end
  return true
end

local node_to_item = function (node)
  local uri = (node.loc.uri or node.loc.targetUri)  
  local filename = string.gsub(uri,"file://","")
  local range = node.loc.range or node.loc.targetSelectionRange
  local lnum = range.start.line+1
  local col = range.start.character+1
  local text = node.text
  return {filename=filename,lnum=lnum,col=col,text=text}
end

function _G.dump_qflist()
  _G.PIG_menu.menu_props.on_close() 
  vim.fn.setqflist({},'r')
  local nodes = _G.PIG_menu._tree:get_nodes()
  local items = {}
  for i,node in ipairs(nodes) do
    if node.is_ref then
      table.insert(items,node_to_item(node))
    end
  end
  vim.fn.setqflist(items)
  vim.cmd [[copen]]
end

local function prepare_new_text(line,loc,new_name)
  local range = loc.range or loc.targetSelectionRange
  local start_char = range.start.character + 1
  local end_char = range['end'].character
  local old_name = string.sub(line, start_char, end_char)
  local left = string.sub(line,1,start_char-1)
  local mid = new_name
  local right = string.sub(line,end_char+1,#line)
  return require('nui.text')(left .. mid .. right, "Comment")
end

local Inc_loc = function(loc,index)
  local new_loc = deepcopy(loc)
  if loc.targetSelectionRange then
    new_loc.targetSelectionRange = {
      ['end'] = {
        character = 0,
        line = loc.targetSelectionRange['end'].line + index
      },
      ['start'] = {
        character = 0,
        line = loc.targetSelectionRange['start'].line + index
      }
    }
  end
  if loc.range then
    new_loc.range = {
      ['end'] = {
        character = 0,
        line = loc.range['end'].line + index
      },
      ['start'] = {
        character = 0,
        line = loc.range['start'].line + index
      }
    }
  end
  if loc.targetRange then
    new_loc.targetRange = {
      ['end'] = {
        character = 0,
        line = loc.targetRange['end'].line + index
      },
      ['start'] = {
        character = 0,
        line = loc.targetRange['start'].line + index
      }
    }
  end
  return new_loc
end

local make_menu = function(groups,ctx)
  -- groups: seperated by files
  local menus = {}
  local ctx_lines = 2 -- lines of context
  local total_lines = 0
  local location_id = 0
  for i,group in ipairs(groups) do
    local file_name = fn.fnamemodify(vim.uri_to_fname(group[1]),':~:.')
    table.insert(menus,Menu.separator(file_name,{text_align = "left"}))
    total_lines = total_lines + 1
    for j = 2, #group do
      local loc = group[j]
      local item = lsp.util.locations_to_items({loc},vim.lsp.get_client_by_id(ctx.client_id).offset_encoding)[1]
      local range = loc.range or loc.targetSelectionRange
      location_id = location_id + 1
      table.insert(menus,Menu.separator("location " .. location_id, {text_align = "left"}))
      total_lines = total_lines + 1
      for k = -ctx_lines,ctx_lines do
        ---- NOTE: any lines in the same context block refer to the same location
        local ctx_loc = Inc_loc(loc,k)
        if not ctx_loc then
          return error("ErrorMsg loc nil: " .. vim.inspect(loc))
        end
        local ctx_item = lsp.util.locations_to_items({ctx_loc},vim.lsp.get_client_by_id(ctx.client_id).offset_encoding)[1]
        total_lines = total_lines + 1
        if ctx.new_name and k==0 then
          local new_line = prepare_new_text(ctx_item.text,loc,ctx.new_name)
          -- NOTE: total_lines-k means: always point to the true ref line, not the ctx line
          table.insert(menus,Menu.item(ctx_item.text, {new_name=ctx.new_name,loc=loc,ctx=ctx,item=item,is_ref=true,line=total_lines-k,col=range.start.character}))
          total_lines = total_lines + 1
          table.insert(menus,Menu.item(new_line, {PIG_skip=true,loc=loc,ctx=ctx,item=item,is_ref=false,line=total_lines-k,col=range.start.character}))
        else
          table.insert(menus,Menu.item(ctx_item.text, {loc=loc,ctx=ctx,item=item,is_ref=(k==0),line=total_lines-k,col=range.start.character}))
        end
      end
    end
  end
  return menus
end

local function builtin_preview_handler(label, result, ctx, config)
  local locations = vim.tbl_islist(result) and result or {result}
  vim.lsp.util.preview_location(locations[1])
end

function _G._goto_next_loc_in_menu(index)
  local nodes = _G.PIG_menu._tree:get_nodes()
  local length = #nodes
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]

  local result = nil
  if index < 0 then
    Start = current_line - 1
    End = 1
    Step = -1
  else
    Start = current_line + 1 -- the line number is also the id of node
    End = length
    Step = 1
  end
  local first_ref_node
  local last_ref_node
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
      if index > 0 then
        if node.line > current_line then
          result = node
          break
        elseif node.line == current_line and node.col > current_col then
          result = node
          break
        end
      else
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
  vim.api.nvim_win_set_cursor(0, {result.line, result.col})
  return result
end

function _G._goto_next_file_in_menu(index)
  local nodes = _G.PIG_menu._tree:get_nodes()
  local length = #nodes
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_node = _G.PIG_menu._tree:get_node(current_line)
  while not current_node.loc do
    current_line = current_line + 1
    current_node = _G.PIG_menu._tree:get_node(current_line)
  end
  local current_uri = current_node.loc.uri or current_node.loc.targetUri

  local first_ref_node
  local last_ref_node
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
      local node_uri = node.loc.uri or node.loc.targetUri
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
  vim.api.nvim_win_set_cursor(0, {result.line, result.col})
  return result
end

local filter_locations_by_uri = function(locations,pattern)
  local results = {} 
  for _,loc in ipairs(locations) do
    local uri = loc.uri or loc.targetUri
    local matched = vim.api.nvim_eval(string.format([['%s' =~ '%s']],uri,pattern))
    if matched==1 then
      table.insert(results,loc)
    end
  end 
  return results
end

local function next_ref_handler(label, result, ctx, config)
  local locations = vim.tbl_islist(result) and result or {result}
  local sorted_locations = sort_locations(locations)
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  local current_file = "file://" .. vim.api.nvim_buf_get_name(ctx.bufnr or 0)
  local filtered_locations = filter_locations_by_uri(sorted_locations,current_file) -- only search the next_ref in current file
  local current_loc = nil
  local index = ctx.index 
  if not index or index==0 then
    return 
  end
  for i,loc in ipairs(filtered_locations) do
    local _start = loc.range.start
    local _end = loc.range['end']
    local condition = _start.line+1 == current_line and
    _start.character <= current_col and
    _end.line+1 >= current_line and
    _end.character >= current_col
    if condition then 
      current_loc = i
      break
    end
  end
  if not current_loc then
    error("weird: cannot find current location")
    return false
  end
  local target = current_loc + index
  if target > #filtered_locations then
    target = 1
  end
  if target < 1 then
    target = #filtered_locations
  end
  vim.lsp.util.jump_to_location(filtered_locations[target],vim.lsp.get_client_by_id(ctx.client_id).offset_encoding)
  return true
end

M.location_handler = function(label, result, ctx, config)
  -- print("token M: ",vim.inspect(M.token))
  -- print("token H: ",vim.inspect(ctx.token))
  if not deep_equal(M.token,ctx.token) then
    -- print("outdated PIG call")
    return -- only handler the newest request (supported by token comparison)
  end
  M.request_func = {} -- reset the cancel function
  local ft = vim.api.nvim_buf_get_option(ctx.bufnr, 'ft')
  local locations = vim.tbl_islist(result) and result or {result}
  local sorted_locations = sort_locations(locations)
  local groups = group_by_uri(sorted_locations)
  local ok,menus = pcall(make_menu,groups,ctx)
  if not ok then
    return false
  end
  if _G.PIG_menu then
    _G.PIG_menu = nil
  end
  local menu = Menu(
    popup_options,
    {
      lines = menus,
      min_width = 40,
      max_width = 80,
      keymap = {
        focus_next = { "n", "<Down>", "<Tab>" },
        focus_prev = { "e", "<Up>", "<S-Tab>" },
        close =  { "<Esc>", "<C-c>" },
        submit = { "<CR>", "<Space>" },
      },
      should_skip_item = function(item)
        if item._type == "separator" then 
          return true
        else
          return item.PIG_skip
        end
      end,
      on_close = function()
        print("PIG CLOSED")
      end,
      on_change = function(node,menu)
        _G.PIG_node = node
      end,
      on_submit = function(item)
        if label == "Refactor" then
          -- _G.PIG_menu:unmount() -- focus on the original buffer
          local params = _G.PIG_menu.rename_params
          vim.lsp.buf_request(0,'textDocument/rename', params)
        else
          local loc = item.loc
          if loc then
            lsp.util.jump_to_location(loc,vim.lsp.get_client_by_id(item.ctx.client_id).offset_encoding)
          else
            echo('ErrorMsg', "can't jump to location")
          end
        end
      end,
    }
  )
  menu.rename_params = ctx.rename_params
  menu:mount() -- call the render here
  _G.PIG_menu = menu
  vim.api.nvim_buf_call(menu.bufnr,function ()
    _goto_next_loc_in_menu(1)
  end)
  vim.api.nvim_buf_set_option(menu.bufnr,"ft",ft) -- set the highlight for ft
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","]]",":lua _goto_next_loc_in_menu(1)<CR>",{noremap=true})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","[[",":lua _goto_next_loc_in_menu(-1)<CR>",{noremap=true})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","]f",":lua _goto_next_file_in_menu(1)<CR>",{noremap=true})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","[f",":lua _goto_next_file_in_menu(-1)<CR>",{noremap=true})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","<leader>q",":lua dump_qflist()<CR>",{noremap=true})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","<leader>s",":silent lua PIG_menu.menu_props.on_close()<CR>:silent sp<CR>:silent lua vim.lsp.util.jump_to_location(PIG_node.loc,vim.lsp.get_client_by_id(PIG_node.ctx.client_id).offset_encoding)<CR>",{noremap=true})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","<leader>v",":silent lua PIG_menu.menu_props.on_close()<CR>:silent vsp<CR>:silent lua vim.lsp.util.jump_to_location(PIG_node.loc,vim.lsp.get_client_by_id(PIG_node.ctx.client_id).offset_encoding)<CR>",{noremap=true})
  return true
end


M.wrap_handler = function (handler)
  local wrapper = function(err, result, ctx, config)
    PIG_state[handler.label] = "success"
    if err or (not result or vim.tbl_isempty(result)) then
      PIG_state[handler.label] = "failure"
      if handler.fallback then
        handler.fallback()
      end
      return echo('ErrorMsg: ', err and err.message or fmt('No %s found', string.lower(handler.label)))
    end
    -- for next_lsp_reference handler
    if handler.label == "NextReference" then
      if handler.index then
        ctx.index = handler.index
      else
        error("ErrorMsg","no index for the next_lsp_reference")
      end
    end
    -- for refact
    if handler.label == "Refactor" then
      if handler.new_name then
        ctx.new_name = handler.new_name
      else
        error("ErrorMsg","no new_name for the refactor")
      end
      ctx.rename_params = handler.rename_params
    end
    ctx.token = handler.token
    local hdl_result = handler.target(handler.label, result, ctx, config)
    if not hdl_result then
      PIG_state[handler.label] = "failure"
      if handler.fallback then
        handler.fallback()
      end
      return echo('ErrorMsg: ', err and err.message or "PIG failed (maybe not lsp)")
    end
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
  ['textDocument/definition'] = {label = 'Definitions', target = M.location_handler},
  ['textDocument/references'] = {label = 'References', target = M.location_handler}
}

M.request_func = {} -- 1: methods name, 2: cancel_handler
M.cancel_request = function ()
  if type(M.request_func[2]) ~= 'function' then return end
  print('cancel PIG buf_request: ',M.request_func[1])
  M.request_func[2]()
  for k,v in pairs(_G.PIG_state) do
    _G.PIG_state[k] = "init"
  end
  M.request_func = {} -- reset
  -- print("release the lock")
end

M.setup_handler = function ()
  for k,v in pairs(handlers) do
    vim.lsp.handlers[k] = M.wrap_handler(v)
  end
end

M.async_ref = function (fallback)
  if not PIG_in_progress() then
    local ref_params = vim.lsp.util.make_position_params()
    ref_params.context = { includeDeclaration = true }
    local token = vim.api.nvim_win_get_cursor(0)
    local clock = os.clock()
    M.token = {token[1],token[2],clock}
    local _,result = vim.lsp.buf_request(0,'textDocument/references', ref_params, M.wrap_handler{label = 'References', target = M.location_handler,fallback=fallback,token={token[1],token[2],clock}})
    M.request_func[1] = "References"
    M.request_func[2] = result
    _G.PIG_state.References="in_progress"
  else
    print("sorry PIG is running, wait!")
  end
end

M.async_def = function (fallback)
  if not PIG_in_progress() then
    local ref_params = vim.lsp.util.make_position_params()
    ref_params.context = { includeDeclaration = false }
    local token = vim.api.nvim_win_get_cursor(0)
    local clock = os.clock()
    M.token = {token[1],token[2],clock}
    local _,result = vim.lsp.buf_request(0,'textDocument/definition', ref_params, M.wrap_handler{label = 'Definitions', target = M.location_handler, fallback=fallback,token={token[1],token[2],clock}})
    M.request_func[1] = "Definitions"
    M.request_func[2] = result
    _G.PIG_state.Definitions="in_progress"
  else
    print("sorry PIG is running, wait!")
  end
end

M.async_typedef = function (fallback)
  if not PIG_in_progress() then
    local ref_params = vim.lsp.util.make_position_params()
    ref_params.context = { includeDeclaration = false }
    local token = vim.api.nvim_win_get_cursor(0)
    local clock = os.clock()
    M.token = {token[1],token[2],clock}
    local token = vim.api.nvim_win_get_cursor(0)
    local clock = os.clock()
    M.token = {token[1],token[2],clock}
    local _,result = vim.lsp.buf_request(0,'textDocument/typeDefinition', ref_params, M.wrap_handler{label = 'TypeDefinitions', target = M.location_handler,fallback=fallback,token={token[1],token[2],clock}})
    M.request_func[1] = "TypeDefinitions"
    M.request_func[2] = result
    _G.PIG_state.TypeDefinitions="in_progress"
  else
    print("sorry PIG is running, wait!")
  end
end

M.async_declare = function (fallback)
  if not PIG_in_progress() then
    local ref_params = vim.lsp.util.make_position_params()
    ref_params.context = { includeDeclaration = false }
    local token = vim.api.nvim_win_get_cursor(0)
    local clock = os.clock()
    M.token = {token[1],token[2],clock}
    local _,result = vim.lsp.buf_request(0,'textDocument/declaration', ref_params, M.wrap_handler{label = 'Declarations', target = M.location_handler,fallback=fallback,token={token[1],token[2],clock}})
    M.request_func[1] = "Declarations"
    M.request_func[2] = result
    _G.PIG_state.Declarations="in_progress"
  else
    print("sorry PIG is running, wait!")
  end
end

M.async_implement = function (fallback)
  if not PIG_in_progress() then
    local ref_params = vim.lsp.util.make_position_params()
    ref_params.context = { includeDeclaration = false }
    local token = vim.api.nvim_win_get_cursor(0)
    local clock = os.clock()
    M.token = {token[1],token[2],clock}
    local _,result = vim.lsp.buf_request(0,'textDocument/implementation', ref_params, M.wrap_handler{label = 'Implementations', target = M.location_handler,fallback=fallback,token={token[1],token[2],clock}})
    M.request_func[1] = "Implementations"
    M.request_func[2] = result
    _G.PIG_state.Implementations="in_progress"
  else
    print("sorry PIG is running, wait!")
  end
end

M.next_lsp_reference = function (index,fallback)
  if not PIG_in_progress() then
    local ref_params = vim.lsp.util.make_position_params()
    ref_params.context = { includeDeclaration = true }
    local token = vim.api.nvim_win_get_cursor(0)
    local clock = os.clock()
    M.token = {token[1],token[2],clock}
    local _,result = vim.lsp.buf_request(0,'textDocument/references', ref_params, M.wrap_handler{label = 'NextReference', target = next_ref_handler, fallback=fallback, index=index,token={token[1],token[2],clock}})
    M.request_func[1] = "NextReference"
    M.request_func[2] = result
    _G.PIG_state.NextReference="in_progress"
  else
    print("sorry PIG is running, wait!")
  end
end

M.rename = function(new_name)
  local opts = {
    prompt = "New Name: "
  }

  ---@private
  local function on_confirm(input)
    if not (input and #input > 0) then return end
    if not PIG_in_progress() then
      local ref_params = vim.lsp.util.make_position_params()
      ref_params.context = { includeDeclaration = true }
      local rename_params = deepcopy(ref_params)
      rename_params.newName = input
      local token = vim.api.nvim_win_get_cursor(0)
      local clock = os.clock()
      M.token = {token[1],token[2],clock}
      local _,result = vim.lsp.buf_request(0,'textDocument/references', ref_params, M.wrap_handler{label = 'Refactor', target = M.location_handler, new_name = input, rename_params = rename_params, token={token[1],token[2],clock}})
      M.request_func[1] = "Refactor"
      M.request_func[2] = result
      _G.PIG_state.Refactor="in_progress"
    else
      print("sorry PIG is running, wait!")
    end
  end

  ---@private
  local function prepare_rename(err, result)
    if err == nil and result == nil then
      vim.notify('nothing to rename', vim.log.levels.INFO)
      return
    end
    if result and result.placeholder then
      opts.default = result.placeholder
      if not new_name then pcall(vim.ui.input, opts, on_confirm) end
    elseif result and result.start and result['end'] and
      result.start.line == result['end'].line then
      local line = vim.fn.getline(result.start.line+1)
      local start_char = result.start.character+1
      local end_char = result['end'].character
      opts.default = string.sub(line, start_char, end_char)
      if not new_name then pcall(vim.ui.input, opts, on_confirm) end
    else
      opts.default = vim.fn.expand('<cword>')
      if not new_name then pcall(vim.ui.input, opts, on_confirm) end
    end
    if new_name then on_confirm(new_name) end
  end
  vim.lsp.buf_request(0,'textDocument/prepareRename', vim.lsp.util.make_position_params(), prepare_rename)
end

local _q = function (key)
  return vim.api.nvim_replace_termcodes(key, true, false, true)
end

M.my_ctrl_c = function ()
  M.cancel_request()
  vim.api.nvim_feedkeys(_q("<C-c>"),'n',true)
end

require("core.utils").map("n","<C-c>","<Cmd>lua require('contrib.my_lsp_handler').my_ctrl_c()<CR>")

return M
