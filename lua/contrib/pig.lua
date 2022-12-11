local api, cmd, fn, g, vim = vim.api, vim.cmd, vim.fn, vim.g, vim
local lsp = require 'vim.lsp'
local fmt = string.format
local current_actions = {}  -- hold all currently available code actions
local last_results = {}     -- hold last location results
local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event

local M = {}
-- serve as a lock
local PIG_state = {
  References = "init",
  Definitions = "init",
  TypeDefinitions = "init",
  Declarations = "init",
  Implementations = "init",
  NextReference = "init",
  Refactor = "init",
}

local PIG_menu = nil
local PIG_window = nil
local PIG_node = nil
local last_source_bufnr = nil
local last_source_buf_location = nil
local last_winnr = nil
local last_PIG_location = nil
local last_PIG_call_params = nil
local pig_ns = vim.api.nvim_create_namespace("PIG")
local rename_lines = {}
local ref_lines = {}
local file_lines = {}
local au_group = vim.api.nvim_create_augroup("PIG",{clear=true})

local function PIG_in_progress()
  local in_progress = false
  for k,v in pairs(PIG_state) do
    if v=="in_progress" then
      in_progress = true
      break
    end
  end
  return in_progress
end

local popup_options = {
  position = "50%",
  -- position = {
  --   row = 0,
  --   col = 0,
  -- },
  size = {
    -- width = 40,
    height = 20,
  },
  -- relative = "cursor",
  border = {
    style = "double",
    text = {
      top = "PIG:🐷",
      top_align = "center",
    },
  },
  win_options = {
    winhighlight = "Normal:Normal,FloatBorder:Normal",
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
--[=====[ TODO:
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
--   targetUri = "file:///home/heke/.config/nvim/contrib/pig.lua"
-- }
--
-- "item" {
--   col = 9,
--   filename = "/home/heke/.config/nvim/contrib/pig.lua",
--   lnum = 91,
--   text = "  local menus = {}"
-- }
----]=====]

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


local node_to_item = function (node)
  local uri = (node.loc.uri or node.loc.targetUri)
  local filename = string.gsub(uri,"file://","")
  local range = node.loc.range or node.loc.targetSelectionRange
  local lnum = range.start.line+1
  local col = range.start.character+1
  local text = node.text
  return {filename=filename,lnum=lnum,col=col,text=text}
end

local function dump_qflist()
  PIG_menu.menu_props.on_close()
  vim.fn.setqflist({},'r')
  local nodes = PIG_menu._tree:get_nodes()
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
  local mid = new_name .. old_name
  local right = string.sub(line,end_char+1,#line)
  -- return require('nui.text')(left .. mid .. right, "htmlStrike")
  return left .. mid .. right, {start_col=start_char-1+#new_name,end_col=end_char+#new_name}
end

local Inc_loc = function(loc,index)
  local new_loc = deepcopy(loc)
  for i,k in ipairs({"targetSelectionRange","range","targetRange"}) do
    if loc[k] ~= nil then
      new_loc[k] = {
        ['end'] = {
        character = 0,
        line = loc[k]['end'].line + index
      },
      ['start'] = {
        character = 0,
        line = loc[k]['start'].line + index
      }
    }
    end
  end
  return new_loc
end

local make_menu = function(groups,ctx)
  rename_lines = {}
  -- groups: seperated by files
  local menus = {}
  local ctx_lines = 2 -- lines of context
  local total_lines = 0
  local location_id = 0
  for i,group in ipairs(groups) do
    local file_name = fn.fnamemodify(vim.uri_to_fname(group[1]),':~:.')
    table.insert(menus,Menu.separator('File: ' .. file_name,{text_align = "left"}))
    total_lines = total_lines + 1
    table.insert(file_lines,{line=total_lines-1,start_col=0,end_col=-1})
    for j = 2, #group do
      local loc = group[j]
      local item = lsp.util.locations_to_items({loc},vim.lsp.get_client_by_id(ctx.client_id).offset_encoding)[1]
      local range = loc.range or loc.targetSelectionRange
      location_id = location_id + 1
      table.insert(menus,Menu.separator("Loc: " .. location_id, {text_align = "left"}))
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
          -- local new_line = prepare_new_text(ctx_item.text,loc,ctx.new_name)
          -- -- NOTE: total_lines-k means: always point to the true ref line, not the ctx line
          -- table.insert(menus,Menu.item(ctx_item.text, {new_name=ctx.new_name,loc=loc,ctx=ctx,item=item,is_ref=true,line=total_lines-k,col=range.start.character}))
          -- total_lines = total_lines + 1
          -- table.insert(menus,Menu.item(new_line, {PIG_skip=true,loc=loc,ctx=ctx,item=item,is_ref=false,line=total_lines-k,col=range.start.character}))
          local new_text,_rename_location = prepare_new_text(ctx_item.text,loc,ctx.new_name)
          table.insert(menus,Menu.item(new_text, {new_name=ctx.new_name,loc=loc,ctx=ctx,item=item,is_ref=(k==0),line=total_lines-k,col=range.start.character}))
          table.insert(rename_lines,vim.tbl_deep_extend('force',_rename_location,{line=total_lines-1}))
        else
          table.insert(menus,Menu.item(ctx_item.text, {loc=ctx_loc,ctx=ctx,item=item,is_ref=(k==0),line=total_lines-k,col=range.start.character}))
        end
        if k==0 then
          table.insert(ref_lines,{line=total_lines-1,start_col=0,end_col=-1})
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

local function _goto_next_loc_in_menu(index)
  local nodes = PIG_menu._tree:get_nodes()
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

local function _goto_next_file_in_menu(index)
  local nodes = PIG_menu._tree:get_nodes()
  local length = #nodes
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_node = PIG_menu._tree:get_node(current_line)
  while not current_node.loc do
    current_line = current_line + 1
    current_node = PIG_menu._tree:get_node(current_line)
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
  if M.ctrl_c_pressed then
    print("ok to show menu, but ctrl_c_pressed")
    return true
  end
  -- print("token M: ",vim.inspect(M.token))
  -- print("token H: ",vim.inspect(ctx.token))
  if not deep_equal(M.token,ctx.token) then
    -- print("outdated PIG call")
    return true -- only handler the newest request (supported by token comparison)
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
  if PIG_menu then
    PIG_menu = nil
  end
  local menu = Menu(
    popup_options,
    {
      lines = menus,
      -- min_width = 40,
      max_width = math.floor(vim.fn.winwidth(0)*0.8),
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
        vim.api.nvim_buf_clear_namespace(0,pig_ns,0,-1)
        PIG_window = nil
      end,
      on_change = function(node,menu)
        PIG_node = node
      end,
      on_submit = function(item)
        if label == "Refactor" then
          -- PIG_menu:unmount() -- focus on the original buffer
          local params = PIG_menu.rename_params
          vim.lsp.buf_request(0,'textDocument/rename', params)
          require("contrib.my_document_highlight").kk_clear_highlight()
          -- if params.highlight ~= nil then
          --   vim.defer_fn(function()
          --     require("contrib.my_document_highlight").kk_highlight()
          --   end,20)
          -- end
        else
          local loc = item.loc
          if loc then
            if last_PIG_call_params then
              -- use stack
              to_search = {{loc,{}}}
              while #to_search > 0 do
                pop = to_search[#to_search][1]
                path = to_search[#to_search][2]
                to_search[#to_search] = nil
                for k,v in pairs(pop) do
                  if k=='character' then
                    -- change the node
                    pop[k] = last_PIG_location[2]
                    -- NOTE: you cannot use the following way, this will not change the loc table
                    -- v = last_PIG_location[2]

                  else 
                    if type(v)=="table" then
                      first = v
                      now_path = vim.deepcopy(path)
                      now_path[#now_path+1] = k
                      second = now_path
                      to_search[#to_search+1] =  {first,second}
                    end
                  end
                end
              end
              vim.pretty_print("loc",loc)

              lsp.util.jump_to_location(loc,vim.lsp.get_client_by_id(item.ctx.client_id).offset_encoding)
            else
              lsp.util.jump_to_location(loc,vim.lsp.get_client_by_id(item.ctx.client_id).offset_encoding)
            end
          else
            echo('ErrorMsg', "can't jump to location")
          end
        end
        PIG_menu.menu_props.on_close()
      end,
    }
  )
  menu.rename_params = ctx.rename_params

  last_source_bufnr = vim.fn.bufnr()
  last_winnr = vim.fn.winnr()
  last_source_buf_location = {ctx.token[1],ctx.token[2]}
  -- ========== now everything is saved
  menu:mount()
  -- ========== render PIG
  PIG_menu = menu
  last_PIG_call_params = {label, result, ctx, config}
  vim.api.nvim_buf_set_option(menu.bufnr,"ft",ft) -- set the highlight for ft
  vim.api.nvim_buf_call(menu.bufnr,function ()
    PIG_window = vim.api.nvim_get_current_win()
    if ctx.resume and last_PIG_location then
      vim.pretty_print('resume to: ',last_PIG_location)
      vim.api.nvim_win_set_cursor(0,last_PIG_location)
    else
      _goto_next_loc_in_menu(1)
    end
    vim.cmd[[TSBufDisable highlight]]
  end)
  vim.api.nvim_create_autocmd("CursorMoved",{callback = function()
    last_PIG_location = vim.api.nvim_win_get_cursor(PIG_window)
  end, buffer = menu.bufnr, group=au_group})

  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","]r","",{noremap=true,callback=function ()
    _goto_next_loc_in_menu(1)
  end})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","[r","",{noremap=true,callback=function ()
    _goto_next_loc_in_menu(-1)
  end})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","]f","",{noremap=true, callback=function ()
    _goto_next_file_in_menu(1)
  end})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","[f","",{noremap=true,callback=function ()
    _goto_next_file_in_menu(-1)
  end})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n","<leader>q","",{noremap=true,callback=dump_qflist})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n",",s","",{noremap=true,callback=function ()
    M.open_split('h')
  end})
  vim.api.nvim_buf_set_keymap(menu.bufnr,"n",",v","",{noremap=true,callback=function ()
    M.open_split('v')
  end})

  vim.keymap.set("n",",g","",{noremap=true,callback=function ()
    vim.cmd(fmt('%s wincmd w',last_winnr))
    vim.cmd(fmt('b %s',last_source_bufnr))
    vim.cmd('wincmd o')
    vim.pretty_print('last_source_buf_location: ',last_source_buf_location)
    vim.api.nvim_win_set_cursor(0,last_source_buf_location)
    last_PIG_call_params[3].resume = true
    vim.pretty_print('last_PIG_call_params: ','result: ',#last_PIG_call_params[2],' ctx: ',ctx)
    M.location_handler(unpack(last_PIG_call_params))
  end})

  for _, loc in ipairs(rename_lines) do
    vim.api.nvim_buf_add_highlight(menu.bufnr,pig_ns,"Error",loc.line,loc.start_col,loc.end_col)
  end

  for _, loc in ipairs(file_lines) do
    vim.api.nvim_buf_add_highlight(menu.bufnr,pig_ns,"htmlBold",loc.line,loc.start_col,loc.end_col)
  end

  for _, loc in ipairs(ref_lines) do
    vim.api.nvim_buf_add_highlight(menu.bufnr,pig_ns,"Visual",loc.line,loc.start_col,loc.end_col)
  end
  return true
end

M.open_split = function(direction)
  PIG_menu.menu_props.on_close()
  if direction=="h" then
    vim.cmd [[split]]
  else
    vim.cmd [[vsplit]]
  end
  vim.lsp.util.jump_to_location(PIG_node.loc,vim.lsp.get_client_by_id(PIG_node.ctx.client_id).offset_encoding)
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
    ctx.resume = handler.resume
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
  for k,v in pairs(PIG_state) do
    PIG_state[k] = "init"
  end
  M.ctrl_c_pressed = true
  M.request_func = {} -- reset
  -- print("release the lock")
end

M.setup_handler = function ()
  for k,v in pairs(handlers) do
    vim.lsp.handlers[k] = M.wrap_handler(v)
  end
end

M.async_ref = function (fallback,resume)
  if not PIG_in_progress() then
    M.ctrl_c_pressed = false
    local ref_params = vim.lsp.util.make_position_params()
    ref_params.context = { includeDeclaration = true }
    local token = vim.api.nvim_win_get_cursor(0)
    local clock = os.clock()
    M.token = {token[1],token[2],clock}
    local _,result = vim.lsp.buf_request(0,'textDocument/references', ref_params, M.wrap_handler{label = 'References', target = M.location_handler,resume=resume, fallback=fallback,token={token[1],token[2],clock}})
    M.request_func[1] = "References"
    M.request_func[2] = result
    PIG_state.References="in_progress"
  else
    print("sorry PIG is running, wait!")
  end
end

M.async_def = function (fallback)
  if not PIG_in_progress() then
    M.ctrl_c_pressed = false
    local ref_params = vim.lsp.util.make_position_params()
    ref_params.context = { includeDeclaration = false }
    local token = vim.api.nvim_win_get_cursor(0)
    local clock = os.clock()
    M.token = {token[1],token[2],clock}
    local _,result = vim.lsp.buf_request(0,'textDocument/definition', ref_params, M.wrap_handler{label = 'Definitions', target = M.location_handler, fallback=fallback,token={token[1],token[2],clock}})
    M.request_func[1] = "Definitions"
    M.request_func[2] = result
    PIG_state.Definitions="in_progress"
  else
    print("sorry PIG is running, wait!")
  end
end

M.async_typedef = function (fallback)
  if not PIG_in_progress() then
    M.ctrl_c_pressed = false
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
    PIG_state.TypeDefinitions="in_progress"
  else
    print("sorry PIG is running, wait!")
  end
end

M.async_declare = function (fallback)
  if not PIG_in_progress() then
    M.ctrl_c_pressed = false
    local ref_params = vim.lsp.util.make_position_params()
    ref_params.context = { includeDeclaration = false }
    local token = vim.api.nvim_win_get_cursor(0)
    local clock = os.clock()
    M.token = {token[1],token[2],clock}
    local _,result = vim.lsp.buf_request(0,'textDocument/declaration', ref_params, M.wrap_handler{label = 'Declarations', target = M.location_handler,fallback=fallback,token={token[1],token[2],clock}})
    M.request_func[1] = "Declarations"
    M.request_func[2] = result
    PIG_state.Declarations="in_progress"
  else
    print("sorry PIG is running, wait!")
  end
end

M.async_implement = function (fallback)
  if not PIG_in_progress() then
    M.ctrl_c_pressed = false
    local ref_params = vim.lsp.util.make_position_params()
    ref_params.context = { includeDeclaration = false }
    local token = vim.api.nvim_win_get_cursor(0)
    local clock = os.clock()
    M.token = {token[1],token[2],clock}
    local _,result = vim.lsp.buf_request(0,'textDocument/implementation', ref_params, M.wrap_handler{label = 'Implementations', target = M.location_handler,fallback=fallback,token={token[1],token[2],clock}})
    M.request_func[1] = "Implementations"
    M.request_func[2] = result
    PIG_state.Implementations="in_progress"
  else
    print("sorry PIG is running, wait!")
  end
end

M.next_lsp_reference = function (index,fallback)
  if not PIG_in_progress() then
    M.ctrl_c_pressed = false
    local ref_params = vim.lsp.util.make_position_params()
    ref_params.context = { includeDeclaration = true }
    local token = vim.api.nvim_win_get_cursor(0)
    local clock = os.clock()
    M.token = {token[1],token[2],clock}
    local _,result = vim.lsp.buf_request(0,'textDocument/references', ref_params, M.wrap_handler{label = 'NextReference', target = next_ref_handler, fallback=fallback, index=index,token={token[1],token[2],clock}})
    M.request_func[1] = "NextReference"
    M.request_func[2] = result
    PIG_state.NextReference="in_progress"
  else
    print("sorry PIG is running, wait!")
  end
end

M.rename = function(new_name,highlight)
  local opts = {
    prompt = "New Name: "
  }

  ---@private
  local function on_confirm(input)
    if not (input and #input > 0) then return end
    if not PIG_in_progress() then
      M.ctrl_c_pressed = false
      local ref_params = vim.lsp.util.make_position_params()
      ref_params.context = { includeDeclaration = true }
      local rename_params = deepcopy(ref_params)
      rename_params.newName = input
      rename_params.highlight = highlight
      local token = vim.api.nvim_win_get_cursor(0)
      local clock = os.clock()
      M.token = {token[1],token[2],clock}
      local _,result = vim.lsp.buf_request(0,'textDocument/references', ref_params, M.wrap_handler{label = 'Refactor', target = M.location_handler, new_name = input, rename_params = rename_params, token={token[1],token[2],clock}})
      M.request_func[1] = "Refactor"
      M.request_func[2] = result
      PIG_state.Refactor="in_progress"
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

M.on_attach = function(bufnr)
  vim.api.nvim_buf_set_keymap(bufnr,"n","<C-c>","",{noremap=true,callback=function ()
    M.my_ctrl_c()    
  end})
end

return M
