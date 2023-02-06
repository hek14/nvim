local M = {}
local api, cmd, fn, g, vim = vim.api, vim.cmd, vim.fn, vim.g, vim
local lsp = require 'vim.lsp'
local fmt = string.format
local current_actions = {}  -- hold all currently available code actions
local last_results = {}     -- hold last location results
local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event


local ctx_lines = 3 -- lines of context
local timers = {}
local cancel_fns = {}
local last_source_bufnr = nil
local last_source_buf_location = nil
local last_source_winnr = nil
local last_pig_menu = nil
local last_pig_window = nil
local last_pig_window_location = nil
local last_pig_node = nil
local last_pig_call_params = nil
local PIG_ns = vim.api.nvim_create_namespace("PIG")
local rename_lines = {}
local ref_lines = {}
local file_lines = {}
local au_group = vim.api.nvim_create_augroup("PIG",{clear=true})

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
  last_pig_menu.menu_props.on_close()
  vim.fn.setqflist({},'r')
  local nodes = last_pig_menu._tree:get_nodes()
  local items = {}
  for i,node in ipairs(nodes) do
    if node.is_ref then
      table.insert(items,node_to_item(node))
    end
  end
  vim.fn.setqflist(items)
  vim.cmd [[copen]]
end

local function prepare_new_line(line,loc,new_name)
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
        character = 0, -- don't worry about this, we dont use the character in loc
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
  local menus = {}
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
        if ctx.label == 'rename' and k==0 then
          local new_text,_rename_location = prepare_new_line(ctx_item.text,loc,ctx.new_name)
          table.insert(menus,Menu.item(new_text, {new_name=ctx.new_name,loc=loc,item=item,is_ref=(k==0),line=total_lines-k,col=range.start.character}))
          table.insert(rename_lines,vim.tbl_deep_extend('force',_rename_location,{line=total_lines-1}))
        else
          table.insert(menus,Menu.item(ctx_item.text, {new_name=nil,loc=ctx_loc,item=item,is_ref=(k==0),line=total_lines-k,col=range.start.character}))
        end
        if k==0 then
          table.insert(ref_lines,{line=total_lines-1,start_col=0,end_col=-1})
        end
      end
    end
  end
  return menus
end

local function _goto_next_loc_in_menu(index)
  local nodes = last_pig_menu._tree:get_nodes()
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
  local nodes = last_pig_menu._tree:get_nodes()
  local length = #nodes
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_node = last_pig_menu._tree:get_node(current_line)
  while not current_node.loc do
    current_line = current_line + 1
    current_node = last_pig_menu._tree:get_node(current_line)
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

M.next_ref_handler = function(label, result, ctx, config)
  if not ctx.index or ctx.index==0 then 
    if type(ctx.fallback) == 'function' then
      ctx.fallback()  
    end
    return 
  end
  local locations = vim.tbl_islist(result) and result or {result}
  local sorted_locations = sort_locations(locations)
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  local current_loc = nil
  local index = ctx.index
  for i,loc in ipairs(sorted_locations) do
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
    if type(ctx.fallback) == 'function' then
      ctx.fallback()  
    end
    return false
  end
  local target = current_loc + index
  if target > #sorted_locations then
    target = 1
  end
  if target < 1 then
    target = #sorted_locations
  end
  vim.cmd('normal! m`')
  vim.api.nvim_win_set_cursor(0, {sorted_locations[target].range.start.line + 1, sorted_locations[target].range.start.character})
  return true
end

M.location_handler = function(label, result, ctx, config)
  local ft = vim.api.nvim_buf_get_option(ctx.bufnr, 'ft')
  local locations = vim.tbl_islist(result) and result or {result}
  local sorted_locations = sort_locations(locations)
  local groups = group_by_uri(sorted_locations)
  local lines = make_menu(groups,ctx)
  local popup_options = {
    position = "50%",
    -- position = {
      --   row = 0,
      --   col = 0,
      -- },
      size = {
        -- width = 40,
        height = math.floor(vim.fn.winheight(0)*0.4),
      },
      -- relative = "cursor",
      border = {
        style = "single",
        text = {
          top = "PIG:🐷",
          top_align = "center",
        },
      },
      win_options = {
        winhighlight = "Normal:Normal,FloatBorder:Normal",
      }
    }
  last_pig_menu = Menu(
    popup_options,
    {
      lines = lines,
      min_width = math.floor(vim.fn.winwidth(0)*0.4),
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
        vim.api.nvim_buf_clear_namespace(0,PIG_ns,0,-1)
      end,
      on_change = function(node,menu)
        last_pig_node = node
      end,
      on_submit = function(item)
        if label == "rename" then
          vim.lsp.buf_request(0,'textDocument/rename', ctx.rename_params)
          require("contrib.my_document_highlight").kk_clear_highlight()
        else
          local loc = item.loc
          -- change all of the leaf node, which name is 'character': means the line numeber
          local to_search = {{loc,{}}}
          while #to_search > 0 do
            local pop = to_search[#to_search][1]
            local path = to_search[#to_search][2]
            to_search[#to_search] = nil
            for k,v in pairs(pop) do
              if k=='character' then
                -- change the node
                pop[k] = last_pig_window_location[2]
                -- NOTE: you cannot use the following way, this will not change the loc table
                -- v = last_pig_window_location[2]
                -- a small example here:
                -- local t = {a='x',b='y',c=1}
                -- for k,v in pairs(t) do
                --   if k=='a' then
                --     v = 3 -- will not work, should use t[k] = 3
                --   end
                -- end
                -- vim.pretty_print(t)
              else 
                if type(v)=="table" then
                  local new_path = vim.deepcopy(path)
                  new_path[#new_path+1] = k
                  to_search[#to_search+1] =  {v,new_path}
                end
              end
            end
          end
          lsp.util.jump_to_location(loc,vim.lsp.get_client_by_id(ctx.client_id).offset_encoding)
        end
        last_pig_menu.menu_props.on_close()
      end,
    }
  )
  last_source_bufnr = ctx.bufnr
  last_source_winnr = vim.fn.winnr()
  last_source_buf_location = {ctx.token[1],ctx.token[2]}
  last_pig_call_params = {label, result, ctx, config}
  -- ========== now everything is saved
  last_pig_menu:mount()
  -- ========== render PIG
  vim.api.nvim_buf_set_option(last_pig_menu.bufnr,"ft",ft) -- set the highlight for ft
  vim.api.nvim_buf_call(last_pig_menu.bufnr,function ()
    last_pig_window = vim.api.nvim_get_current_win()
    if ctx.resume then
      vim.api.nvim_win_set_cursor(0,last_pig_window_location)
    else
      _goto_next_loc_in_menu(1)
    end
    vim.cmd[[TSBufDisable highlight]]
  end)
  vim.api.nvim_create_autocmd("CursorMoved",{callback = function()
    last_pig_window_location = vim.api.nvim_win_get_cursor(last_pig_window)
  end, buffer = last_pig_menu.bufnr, group=au_group})

  vim.api.nvim_buf_set_keymap(last_pig_menu.bufnr,"n","]r","",{noremap=true,callback=function ()
    _goto_next_loc_in_menu(1)
  end})
  vim.api.nvim_buf_set_keymap(last_pig_menu.bufnr,"n","[r","",{noremap=true,callback=function ()
    _goto_next_loc_in_menu(-1)
  end})
  vim.api.nvim_buf_set_keymap(last_pig_menu.bufnr,"n","]f","",{noremap=true, callback=function ()
    _goto_next_file_in_menu(1)
  end})
  vim.api.nvim_buf_set_keymap(last_pig_menu.bufnr,"n","[f","",{noremap=true,callback=function ()
    _goto_next_file_in_menu(-1)
  end})
  vim.api.nvim_buf_set_keymap(last_pig_menu.bufnr,"n","<leader>q","",{noremap=true,callback=dump_qflist})
  vim.api.nvim_buf_set_keymap(last_pig_menu.bufnr,"n",",s","",{noremap=true,callback=function ()
    M.open_split('h',ctx)
  end})
  vim.api.nvim_buf_set_keymap(last_pig_menu.bufnr,"n",",v","",{noremap=true,callback=function ()
    M.open_split('v',ctx)
  end})

  vim.keymap.set("n",",g","",{noremap=true,callback=function ()
    vim.cmd(fmt('%s wincmd w',last_source_winnr))
    vim.cmd(fmt('b %s',last_source_bufnr))
    vim.cmd('wincmd o')
    vim.api.nvim_win_set_cursor(0,last_source_buf_location)
    last_pig_call_params[3].resume = true
    M.location_handler(unpack(last_pig_call_params))
  end})

  for _, loc in ipairs(rename_lines) do
    vim.api.nvim_buf_add_highlight(last_pig_menu.bufnr,PIG_ns,"Error",loc.line,loc.start_col,loc.end_col)
  end

  for _, loc in ipairs(file_lines) do
    vim.api.nvim_buf_add_highlight(last_pig_menu.bufnr,PIG_ns,"htmlBold",loc.line,loc.start_col,loc.end_col)
  end

  for _, loc in ipairs(ref_lines) do
    vim.api.nvim_buf_add_highlight(last_pig_menu.bufnr,PIG_ns,"Visual",loc.line,loc.start_col,loc.end_col)
  end
end

M.open_split = function(direction,ctx)
  last_pig_menu.menu_props.on_close()
  if direction=="h" then
    vim.cmd [[split]]
  else
    vim.cmd [[vsplit]]
  end
  if last_pig_node.loc.range then
    last_pig_node.loc.range.start.character = last_pig_window_location[2]
  end
  if last_pig_node.loc.targetRange then
    last_pig_node.loc.targetRange.start.character = last_pig_window_location[2]
  end
  vim.lsp.util.jump_to_location(last_pig_node.loc,vim.lsp.get_client_by_id(ctx.client_id).offset_encoding)
end

M.default_fallback = function(msg)
  vim.notify(msg or 'PIG Fail!',vim.log.levels.ERROR)
end

M.wrap_handler = function (args)
  args.fallback = args.fallback or M.default_fallback
  local wrapper = function(err, result, ctx, config)
    if err or (not result or vim.tbl_isempty(result)) then
      echo('ErrorMsg: ', err and err.message or fmt('No %s found', string.lower(args.label)))
      if args.fallback then
        args.fallback()
      end
      if timers[ctx.bufnr] then
        timers[ctx.bufnr] = nil
      end
      return
    end
    if args.label == "next_reference" then
      if not args.index then
        echo("ErrorMsg","no index for the next_lsp_reference")
        if timers[ctx.bufnr] then
          timers[ctx.bufnr] = nil
        end
        return
      end
    end
    if args.label == "rename" then
      if not (args.new_name and args.rename_params) then
        echo("ErrorMsg","no new_name for the rename")
        if timers[ctx.bufnr] then
          timers[ctx.bufnr] = nil
        end
        return
      end
    end
    ctx = vim.tbl_deep_extend('force',ctx, args)
    if args.label == "next_reference" then
      M.next_ref_handler(args.label, result, ctx, config)
    else
      M.location_handler(args.label, result, ctx, config)
    end
    if timers[ctx.bufnr] then
      timers[ctx.bufnr] = nil
    end
  end
  return wrapper
end

M.override_handler = function ()
  local handlers = {
    ['textDocument/definition'] = {label = 'Definitions', target = M.location_handler},
    ['textDocument/references'] = {label = 'References', target = M.location_handler}
  }
  for k,v in pairs(handlers) do
    vim.lsp.handlers[k] = M.wrap_handler(v)
  end
end

M.async_fn = function(args)
  -- args: table keys: label,fallback,resume,index
  if not args.label then
    vim.notify('PIG: at least provide the label',vim.log.levels.ERROR)
    return
  end 

  local bufnr = vim.api.nvim_get_current_buf()
  if timers[bufnr] then
    print("sorry PIG is running, wait!")
    return
  end

  local timer = vim.loop.new_timer()
  timers[bufnr] = timer
  timer:start(10,0,vim.schedule_wrap(function ()
    local methods = {
      definition = 'textDocument/definition',
      reference = 'textDocument/references',
      next_reference = 'textDocument/documentHighlight',
      rename = 'textDocument/references'
    }
    local ref_params = vim.lsp.util.make_position_params()
    ref_params.context = { includeDeclaration = true }
    local token = M.create_token()
    args.token = token
    args = vim.tbl_deep_extend('force',args,{target=M.location_handler})
    local _,fn = vim.lsp.buf_request(bufnr,methods[args.label], ref_params, M.wrap_handler(args))
    cancel_fns[bufnr] = fn 
  end))
end

M.create_token = function ()
  local location = vim.api.nvim_win_get_cursor(0)
  local clock = os.clock()
  return {location[1],location[2],clock}
end

M.rename = function(new_name,highlight)
  local opts = {
    prompt = "New Name: "
  }
  ---@private
  local function on_confirm(input)
    if not (input and #input > 0) then return end
    local ref_params = vim.lsp.util.make_position_params()
    ref_params.context = { includeDeclaration = true }
    local rename_params = deepcopy(ref_params)
    rename_params.newName = input
    rename_params.highlight = highlight
    M.async_fn({label = 'rename',target = M.location_handler, new_name = input, rename_params = rename_params})
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

M.cancel_request = function (bufnr)
  if timers[bufnr] then
    print(fmt('bufnr %s is running PIG',bufnr))
    if cancel_fns[bufnr] then
      print('has way to cancel the request')
      cancel_fns[bufnr]()
    else
      echo('ErrorMsg','no cancel_fn')
    end
    timers[bufnr] = nil
  else
    print("the request has been handlered, cannot cancel it")
  end
end

M.my_ctrl_c = function (bufnr)
  vim.api.nvim_feedkeys(_q("<C-c>"),'n',true)
  M.cancel_request(bufnr)
end

M.on_attach = function(bufnr)
  vim.api.nvim_buf_set_keymap(bufnr,"n","<C-c>","",{noremap=true,callback=function ()
    M.my_ctrl_c(bufnr)    
  end})
end

return M
