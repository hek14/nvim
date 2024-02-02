local M = {}

_G.p = require('contrib.print_to_buf').liveprint

_G.profile = function(cmd, times, flush)
  times = times or 100
  local start = vim.loop.hrtime()
  for _ = 1, times, 1 do
    if flush then
      ---@diagnostic disable-next-line: undefined-global
      jit.flush(cmd, true)
    end
    cmd()
  end
  print('Profile: ' .. ((vim.loop.hrtime() - start) / 1000000 / times) .. "ms")
end

M.close_buffer = function(force)
  if vim.bo.buftype == "terminal" then
    vim.api.nvim_win_hide(0)
    return
  end

  local fileExists = vim.fn.filereadable(vim.fn.expand "%p")
  local modified = vim.api.nvim_buf_get_option(vim.fn.bufnr(), "modified")

  -- if file doesnt exist & its modified
  if fileExists == 0 and modified then
    vim.notify("no file name? add it now!",vim.log.levels.ERROR)
    return
  end

  force = force or not vim.bo.buflisted or vim.bo.buftype == "nofile"

  -- if not force, change to prev buf and then close current
  -- local close_cmd = force and ":bd!" or ":e #| bd" .. vim.fn.bufnr()
  local close_cmd
  local last_buf = vim.fn.bufnr('#')
  if vim.api.nvim_buf_is_valid(last_buf) and vim.api.nvim_buf_get_option(last_buf,'buflisted') then
    close_cmd = force and ":bd!" or ":b# | bd" .. vim.fn.bufnr()
  else
    close_cmd = force and ":bd!" or ":bp | bd" .. vim.fn.bufnr()
  end
  vim.cmd(close_cmd)
end

M.zoom = function(buf_id, config)
  if M.zoom_winid and vim.api.nvim_win_is_valid(M.zoom_winid) then
    vim.api.nvim_win_close(M.zoom_winid, true)
    M.zoom_winid = nil
  else
    buf_id = buf_id or 0
    -- Currently very big `width` and `height` get truncated to maximum allowed
    local default_config = { relative = 'editor', row = 0, col = 0, width = 1000, height = 1000 }
    config = vim.tbl_deep_extend('force', default_config, config or {})
    M.zoom_winid = vim.api.nvim_open_win(buf_id, true, config)
    vim.cmd('setlocal winblend=0')
    vim.cmd('normal! zz')
  end
end
M.zoom_winid = nil

M.ppid = function()
  local pid = vim.fn.getpid()
  local ppid = vim.trim(vim.fn.system(string.format('ps -p %s -o ppid=',pid)))
  local cmd_str = string.format([[:echo 'current nvim ppid: %s']],ppid)
  vim.api.nvim_echo({
    { "current nvim ppid: " .. ppid,  "Visual" },
    { "" }
  }, true, {})
end

-- hide statusline
M.hide_statusline = function()
  local hidden = {
    "help",
    "NvimTree",
    "terminal",
    "alpha",
  }
  local shown = {}
  local api = vim.api
  local buftype = api.nvim_buf_get_option(0, "ft")

  -- shown table from config has the highest priority
  if vim.tbl_contains(shown, buftype) then
    api.nvim_set_option("laststatus", 3)
    return
  end

  if vim.tbl_contains(hidden, buftype) then
    api.nvim_set_option("laststatus", 0)
    return
  end

  api.nvim_set_option("laststatus", 3)
end

M.deep_equal = function(t1,t2)
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

_G.deep_equal = M.deep_equal

_G.any_client_attached = function (bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  -- local clients = vim.lsp.get_active_clients()
  -- local attached = {}
  -- for i,client in ipairs(clients) do
  --   if vim.lsp.buf_is_attached(bufnr,client.id) then
  --     table.insert(attached,{id=client.id,name=client.name})
  --   end
  -- end
  local attached = {}
  local clients = vim.lsp.get_active_clients({bufnr = bufnr}) or {}
  for id,client in pairs(clients) do
    if client.name~='null-ls' then
      table.insert(attached,{id=id,name=client.name})
    end
  end
  return attached
end

M.map = function(mode, keys, rhs, opt)
  local options = { noremap = true, silent = true }
  if opt then
    options = vim.tbl_extend("force", options, opt)
  end

  -- all valid modes allowed for mappings
  -- :h map-modes
  local valid_modes = {
    ["n"] = true,
    ["v"] = true,
    ["s"] = true,
    ["x"] = true,
    ["o"] = true,
    ["!"] = true,
    ["i"] = true,
    ["l"] = true,
    ["c"] = true,
    ["t"] = true,
  }

  -- helper function for M.map
  -- can gives multiple modes and keys
  local function map_wrapper(sub_mode, lhs)
    if type(lhs)=='string' and lhs:match('|')==nil and valid_modes[sub_mode] then
      if type(rhs)=='string' then
        vim.keymap.set(sub_mode,lhs,rhs,options)
      else 
        if type(rhs)=='function' and (options.expr==nil or options.expr==false) then
          options.callback = rhs
          vim.keymap.set(sub_mode,lhs,'',options)
        else
          options.silent = false
          vim.keymap.set(sub_mode,lhs,rhs,options)
        end
      end
      return
    end

    if type(lhs)=='table' then
      for _,k in ipairs(lhs) do
        map_wrapper(sub_mode,k)
      end
      return
    elseif type(lhs)=="string" and lhs:match('|')~=nil then
      for _,k in ipairs(M.stringSplit(lhs,'|')) do
        map_wrapper(sub_mode,k)
      end
      return
    end

    if type(sub_mode) == 'string' and #sub_mode > 1 then
      for i = 1,#sub_mode do
        local k = string.sub(sub_mode,i,i)
        map_wrapper(k,lhs)
      end
      return
    elseif type(sub_mode)=='table' then
      for _,k in ipairs(sub_mode) do
        map_wrapper(k,lhs)
      end
      return
    else
      local info = debug.getinfo(3,'Sln')
      vim.notify("sub_mode should be table or string",vim.log.levels.ERROR)
      vim.print('sub_mode: ',sub_mode, info)
      return
    end
  end
  map_wrapper(mode, keys)
end

M.del_map = function(mode, lhs, bufnr)
  -- The dummy set before del is done for safety, in case a default mapping does not exist.
  vim.keymap.set(mode, lhs, '', { buffer = bufnr })
  vim.keymap.del(mode, lhs, { buffer = bufnr })
end

-- clear command line from lua
M.clear_cmdline = function()
  vim.defer_fn(function()
    vim.cmd "echo"
  end, 0)
end

function M.quick_eval()
  local path = vim.fn.expand('%:p')
  local base = vim.fn.stdpath('config') .. '/lua/'
  local _start,_end = path:find(base)
  if _start == nil or _end == nil then 
    return nil 
  end
  local partial = string.sub(path,_end+1)
  local comps = string.gsub(partial,'%.lua','')
  comps = string.gsub(comps,'/','.')
  local func = vim.fn.expand("<cword>")
  comps = string.format(':lua =require("%s").%s()',comps,func)
  return comps
end


function M.termcode(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function M.read_json_file(filename)
  local Path = require 'plenary.path'

  local path = Path:new(filename)
  if not path:exists() then
    return nil
  end

  local json_contents = path:read()
  local json = vim.fn.json_decode(json_contents)

  return json
end

function M.read_package_json()
  return M.read_json_file 'package.json'
end
-- clear last echo using feedkeys (this is a bit hacky)
M.clear_last_echo = function()
  -- wrap this with inputsave and inputrestore just in case
  vim.fn.inputsave()
  vim.api.nvim_feedkeys(":", "nx", true)
  vim.fn.inputrestore()
end

-- a wrapper for running terminal commands that also handles errors
-- 1st arg - the command to run
-- 2nd arg - a boolean to indicate whether to print possible errors
-- returns the result if successful, nil otherwise
M.cmd = function(cmd_str, print_error)
  local result = vim.fn.system(cmd_str)
  if vim.api.nvim_get_vvar "shell_error" ~= 0 then
    if print_error then
      vim.api.nvim_err_writeln("Error running command:\n" .. cmd_str .. "\nError message:\n" .. result)
    end
    return nil
  end
  return result
end

M.file = function(mode, filepath, content)
  local data
  filepath = vim.fn.expand(filepath)
  local fd = assert(vim.loop.fs_open(filepath, mode, 438))
  local stat = assert(vim.loop.fs_fstat(fd))
  if stat.type ~= "file" then
    data = false
  else
    if mode == "r" then
      data = assert(vim.loop.fs_read(fd, stat.size, 0))
    else
      assert(vim.loop.fs_write(fd, content, 0))
      data = true
    end
  end
  assert(vim.loop.fs_close(fd))
  return data
end

M.sleep = function(n)
  os.execute("sleep " .. tonumber(n))
end

M.reload_env = function()
  local output = vim.fn.system('source ~/.zshenv ; env')
  output = require('core.utils').stringSplit(vim.trim(output),'\n')
  for _, item in ipairs(output) do
    local res = require('core.utils').stringSplit(item,'=')
    vim.env[res[1]] = res[2]
  end
end

M.append_env_path = function(path)
  local last_char = string.sub(path,#path) 
  if last_char~=':' then
    path = path .. ':'
  end
  vim.env['PATH'] = path .. vim.env['PATH']
end

M.reload_plugin = function(plugins)
  vim.loader.reset()
  local function _reload_plugin(plugin)
    local loaded = package.loaded[plugin]
    if loaded then
      package.loaded[plugin] = nil
    end
    local ok, reloaded_plugin = pcall(require, plugin)
    if not ok then
      print("Error: Cannot load " .. plugin)
      return nil
    else
      return reloaded_plugin
    end
  end

  if type(plugins) == "string" then
    return _reload_plugin(plugins)
  elseif type(plugins) == "table" then
    local reloaded_plugins = {}
    for i, plugin in ipairs(plugins) do
      reloaded_plugins[i] = _reload_plugin(plugin)
    end
    return reloaded_plugins
  end
end

_G.R = M.reload_plugin

-- ========== dir staff

function M.getDirectores(path)
  local data = {}
  local len = #path
  if len <= 1 then
    return nil
  end
  local last_index = 1
  for i = 2, len do
    local cur_char = path:sub(i, i)
    if cur_char == "/" then
      local my_data = path:sub(last_index + 1, i - 1)
      table.insert(data, my_data)
      last_index = i
    end
  end
  return data
end

function M.get_base(path)
  local len = #path
  for i = len, 1, -1 do
    if path:sub(i, i) == "/" then
      local ret = path:sub(i + 1, len)
      return ret
    end
  end
end

function M.get_relative_path(base_path, my_path)
  local base_data = M.getDirectores(base_path)
  local my_data = M.getDirectores(my_path)
  local base_len = #base_data
  local my_len = #my_data
  if (not base_data) or (not my_data) then
    return
  end

  if base_len > my_len then
    return my_path
  end

  if base_data[1] ~= my_data[1] then
    return my_path
  end

  local cur = 0
  for i = 1, base_len do
    if base_data[i] ~= my_data[i] then
      break
    end
    cur = i
  end
  local data = ""
  for i = cur + 1, my_len do
    data = data .. my_data[i] .. "/"
  end
  data = data .. M.get_base(my_path)
  return data
end
-- ==========

M.stringSplit = function(inputstr, sep)
  if sep == '' then
    local t = {}
    for i = 1,#inputstr do
      table.insert(t,inputstr:sub(i,i))
    end
    return t
  end
  sep=sep or '%s'
  local t={}
  for field,s in string.gmatch(inputstr, "([^"..sep.."]*)("..sep.."?)") do
    table.insert(t,field)
    if s=="" then
      return t
    end
  end
end

M.preview_qf = function ()
  local qflist = vim.fn.getqflist()
  local curr = vim.api.nvim_win_get_cursor(0)
  local item = qflist[curr[1]]
  local bufnr = item.bufnr
  local filename = "file:/" .. vim.api.nvim_buf_get_name(bufnr)
  local line = item.lnum
  local location = {
    uri = filename,
    range = {
      ['start'] = {line = line-3},
      ['end'] = {line = line+3},
    }
  }
  -- vim.lsp.util.preview_location(location,{offset_x = 10, offset_y = -vim.api.nvim_win_get_height(0)-10, width = vim.fn.winwidth(0), border = "double"})
  local offset_y = nil
  local delta = curr[1] - vim.fn.line('w0')
  offset_y = 10 + delta + 1
  if delta > 4 then
    offset_y = 10
  end
  vim.lsp.util.preview_location(location,{offset_x = 0, offset_y = -offset_y, width = vim.fn.winwidth(0), border = "double"})
end


function _G.TimeTravel(args)
  local default = os.date("*t")
  ---@diagnostic disable-next-line: unused-local, param-type-mismatch
  args = vim.tbl_extend('force',default,args)
  local old_time = os.time(args)
  local now = os.time()
  local difference_seconds = os.difftime(now, old_time)
  local difference_minutes = math.floor(difference_seconds / (60)) -- seconds in a day
  if difference_seconds > 0 then
    vim.cmd(string.format("earlier %ds",difference_seconds))
  else
    vim.cmd(string.format("later %ds",difference_seconds))
  end
end


function _G.back_to_the_future()
  local time_travel = {menu=nil,tmp_buffer=nil}
  local Menu = require("nui.menu")
  local event = require("nui.utils.autocmd").event
  local og_buffer = vim.api.nvim_get_current_buf()
  time_travel.og_buffer = og_buffer
  local lines = vim.api.nvim_buf_get_lines(og_buffer,0,-1,false)
  time_travel.tmp_buffer = vim.api.nvim_create_buf(true,true)
  time_travel.menu_lines = nil
  -- vim.api.nvim_buf_set_name(time_travel.tmp_buffer,"FILE NOW")
  vim.api.nvim_buf_set_lines(time_travel.tmp_buffer,0,-1,false,lines)
  vim.api.nvim_buf_set_option(time_travel.tmp_buffer,'filetype',vim.api.nvim_buf_get_option(og_buffer,'filetype'))

  local popup_options = {
    position = "50%",
    size = {
      width = 40,
      height = 8,
    },
    relative = "editor",
    border = {
      style = "rounded",
      text = {
        top = "Back to the Future",
        top_align = "center",
      },
    },
    buf_options = {
      modifiable = true,
      readonly = false,
    },
    win_options = {
      winhighlight = "Normal:Normal",
    }
  }
  local default = os.date("*t")
  time_travel.menu = Menu(popup_options, {
    lines = {
      Menu.item(string.format("min: %d",default.min)),
      Menu.item(string.format("hour: %d",default.hour)),
      Menu.item(string.format("day: %d",default.day)),
      Menu.item(string.format("month: %d",default.month)),
      Menu.item(string.format("year: %d",default.year)),
    },
    -- max_width = 20,
    keymap = {
      focus_next = { "n", "<Down>", "<Tab>" },
      focus_prev = { "e", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "<C-c>" },
      submit = { "<CR>" },
    },
    on_close = function()
      print("CLOSED")
    end,
    on_submit = function(_)
      vim.cmd[[exe "normal! \<C-w>\<C-o>"]]
      local old_time = {}
      local info = "go back to: "
      for i = 1,#time_travel.menu_lines do
        local key,value = string.match(time_travel.menu_lines[i],'(%a+): (%d+)')
        old_time[key] = tonumber(value)
        info = info .. string.format('%s: %d%s',key,value,i~=#time_travel.menu_lines and '  ' or '')
      end
      vim.api.nvim_buf_call(time_travel.og_buffer,function()
        TimeTravel(old_time)
      end)
      print(info)
      -- can also use `:windo diffthis`
      vim.cmd(string.format('diffthis | vsp | b %d | diffthis',time_travel.tmp_buffer))
    end,
  })
  time_travel.menu:mount()
  time_travel.menu:on({ event.InsertChange,event.TextChanged,event.TextChangedI,event.TextChangedP},function()
    time_travel.menu_lines = vim.api.nvim_buf_get_lines(time_travel.menu.bufnr,0,-1,false)
  end)
  vim.api.nvim_buf_set_option(time_travel.menu.bufnr,"modifiable",true)
  vim.api.nvim_buf_set_option(time_travel.menu.bufnr,"readonly",false)
  vim.api.nvim_buf_call(time_travel.menu.bufnr,function ()
    vim.cmd[[startinsert]]
    vim.api.nvim_win_set_cursor(0,{1,#time_travel.menu._tree:get_nodes()[1].text})
  end)
end

M.repeat_timer = function(fn)
  local function timedFn()
    local wait = fn()
    if wait>0 then
      vim.defer_fn(timedFn, wait)
    end
  end
  timedFn()
end

M.clear_log = function ()
  local log_path = vim.fn.expand("$HOME") .. "/.cache/nvim/kk_debug.log"
  vim.fn.system('echo > ' .. log_path)
end

local log_path = vim.fn.expand("$HOME") .. "/.cache/nvim/kk_debug.log"
M.log = function (...)
  local start = vim.loop.hrtime()
  local str = "שׁ "
  local lineinfo = ''

  local info = debug.getinfo(2, "Sl")
  lineinfo = info.short_src .. ":" .. info.currentline
  local date = os.date()
  str = str .. date .. ", " .. str .. lineinfo .. '\n'
  local arg = {...}
  vim.schedule(function()
    for i, v in ipairs(arg) do
      if type(v) == "table" then
        str = str .. " |" .. tostring(i) .. ": " .. vim.inspect(v) .. "\n"
      else
        str = str .. " |" .. tostring(i) .. ": " .. tostring(v)
      end
    end
    if #str > 2 then
      if log_path ~= nil and #log_path > 3 then
        local f = io.open(log_path, "a+")
        ---@diagnostic disable-next-line: unused-local, param-type-mismatch
        io.output(f)
        io.write(str .. "=======\n")
        io.close(f)
      else
        print(str .. "\n")
      end
    end
  end)
end 

M.source_curr_file = function()
  if vim.bo.ft == "lua" then
    -- vim.loader.reset()
    vim.cmd [[luafile %]]
  elseif vim.bo.ft == "vim" then
    vim.cmd [[so %]]
  end
end


M.smart_current_dir = function()
  local fname = vim.api.nvim_buf_get_name(0)
  local dir = require('lspconfig').util.find_git_ancestor(fname) or
  vim.fn.expand('%:p:h')
  print("cd " .. dir)
  vim.cmd("cd " .. dir)
end


function M.get_all_window_buffer_filetype()
  local window_buffer_filetype = {}
  local window_tables = vim.api.nvim_list_wins()

  for _, window_id in ipairs(window_tables) do
    if vim.api.nvim_win_is_valid(window_id) then
      local bufnr = vim.api.nvim_win_get_buf(window_id)
      table.insert(window_buffer_filetype, {
        winnr = window_id,
        bufnr = bufnr,
        filetype = vim.api.nvim_buf_get_option(bufnr, "filetype"),
      })
    end
  end

  return window_buffer_filetype
end


M.close_float_window = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(win)
        if config.relative ~= "" then
          pcall(vim.api.nvim_win_close,win,false)
        end
    end
end

M.range_search = function(pattern,_start,_end)
  if pattern == nil then
    pattern = vim.fn.input('Search pattern: ',vim.fn.expand('<cword>'))
  end
  local mode = vim.fn.mode()
  if _start==nil and _end==nil then
    if mode=="n" then
      _start = tonumber(vim.fn.input("Search start: ",1))
      _end = tonumber(vim.fn.input("Search end: ",vim.fn.line('$')))
    else -- visual mode
      ------ method 1
      -- vim.fn.feedkeys([[\<esc>]],'n') -- exit the visual mode, then the visual range got recorded
      -- vim.cmd [[execute "normal! gv\<Esc>"]]
      ------ method 2
      vim.cmd [[execute "normal! \<esc>"]]
      _start = vim.fn.getpos("'<")[2]
      _end = vim.fn.getpos("'>")[2]
    end
  end
  if _start and _end and pattern then
    vim.cmd(string.format([[/\%%>%sl\%%<%sl%s]],_start-1,_end+1,pattern))
  end
end


_G.lsp_num_to_str = {
  [1]  = "File",
  [2]  = "Module",
  [3]  = "Namespace",
  [4]  = "Package",
  [5]  = "Class",
  [6]  = "Method",
  [7]  = "Property",
  [8]  = "Field",
  [9]  = "Constructor",
  [10] = "Enum",
  [11] = "Interface",
  [12] = "Function",
  [13] = "Variable",
  [14] = "Constant",
  [15] = "String",
  [16] = "Number",
  [17] = "Boolean",
  [18] = "Array",
  [19] = "Object",
  [20] = "Key",
  [21] = "Null",
  [22] = "EnumMember",
  [23] = "Struct",
  [24] = "Event",
  [25] = "Operator",
  [26] = "TypeParameter",
}

M.ScopeSearch = function()
  local data = require("nvim-navic").get_data()
  local index = #data - vim.v.count1 + 1
  local node = data[index]
  while node~=nil do
    if vim.tbl_contains({'Module','Class','Method','Function'},lsp_num_to_str[node.kind]) then
      vim.print(node.name)
      break
    else
      index = index - 1
      node = data[index]
    end
  end
  if node==nil then
    print('No Scope Found')
    M.range_search()
  else
    local scope = node.scope
    -- vim.cmd(string.format(':%s | normal! V%sj',scope.start.line,scope['end'].line-scope.start.line))
    M.range_search(nil,scope.start.line,scope['end'].line)
  end
end

M.grep_last_search = function()
  -- search the last buffer search word in CWD
  local register = vim.fn.getreg('/'):gsub('\\<', ''):gsub('\\>', '')

  if register and register ~= '' then
    require('telescope.builtin').grep_string({
      path_display = { 'shorten' },
      search = register,
    })
  else
    require('telescope.builtin').live_grep()
  end
end

local filter_path = function(paths)
  local index = 1
  for _,p in ipairs(paths) do
    if vim.loop.fs_stat(p) then
      paths[index] = p
      index = index + 1
    end
  end
  if index == 1 then
    if vim.loop.fs_stat(paths[1]) then
      return paths
    else
      return {}
    end
  end
  return paths
end

local table_combine = function(table1,table2)
  for i,p in ipairs(table2) do
    table1[#table1+i] = p
  end
  return table1
end

vim.cmd [[
  let g:i = 0
  function! Inc(...)
    let result = g:i
    let g:i += a:0 > 0 ? a:1 : 1
    return result
  endfunction
]]

function M._echo_multiline(msg)
  for _, s in ipairs(vim.fn.split(msg, "\n")) do
    vim.cmd("echom '" .. s:gsub("'", "''") .. "'")
  end
end

function M.info(msg)
  vim.cmd("echohl Directory")
  M._echo_multiline(msg)
  vim.cmd("echohl None")
end

function M.warn(msg)
  vim.cmd("echohl WarningMsg")
  M._echo_multiline(msg)
  vim.cmd("echohl None")
end

function M.err(msg)
  vim.cmd("echohl ErrorMsg")
  M._echo_multiline(msg)
  vim.cmd("echohl None")
end

function M.get_visual_selection(nl_literal)
  -- this will exit visual mode
  -- use 'gv' to reselect the text
  local _, csrow, cscol, cerow, cecol
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "" then
    -- if we are in visual mode use the live position
    _, csrow, cscol, _ = unpack(vim.fn.getpos("."))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("v"))
    if mode == "V" then
      -- visual line doesn't provide columns
      cscol, cecol = 0, 999
    end
    -- exit visual mode
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<Esc>",
        true, false, true), "n", true)
  else
    -- otherwise, use the last known visual position
    _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
  end
  -- swap vars if needed
  if cerow < csrow then csrow, cerow = cerow, csrow end
  if cecol < cscol then cscol, cecol = cecol, cscol end
  local lines = vim.fn.getline(csrow, cerow)
  -- local n = cerow-csrow+1
  local n = #lines
  if n <= 0 then return "" end
  lines[n] = string.sub(lines[n], 1, cecol)
  lines[1] = string.sub(lines[1], cscol)
  return table.concat(lines, nl_literal and "\\n" or "\n")
end


M.sudo_exec = function(cmd, print_output)
  vim.fn.inputsave()
  local password = vim.fn.inputsecret("Password: ")
  vim.fn.inputrestore()
  if not password or #password == 0 then
    M.warn("Invalid password, sudo aborted")
    return false
  end
  local out = vim.fn.system(string.format("sudo -p '' -S %s", cmd), password)
  if vim.v.shell_error ~= 0 then
    print("\r\n")
    M.err(out)
    return false
  end
  if print_output then print("\r\n", out) end
  return true
end

M.sudo_write = function(tmpfile, filepath)
  if not tmpfile then tmpfile = vim.fn.tempname() end
  if not filepath then filepath = vim.fn.expand("%") end
  if not filepath or #filepath == 0 then
    M.err("E32: No file name")
    return
  end
  -- `bs=1048576` is equivalent to `bs=1M` for GNU dd or `bs=1m` for BSD dd
  -- Both `bs=1M` and `bs=1m` are non-POSIX
  local cmd = string.format("dd if=%s of=%s bs=1048576",
    vim.fn.shellescape(tmpfile),
    vim.fn.shellescape(filepath))
  -- no need to check error as this fails the entire function
  vim.api.nvim_exec(string.format("write! %s", tmpfile), true)
  if M.sudo_exec(cmd) then
    M.info(string.format([[\r\n"%s" written]], filepath))
    vim.cmd("e!")
  end
  vim.fn.delete(tmpfile)
end


M.unload_modules = function(patterns)
  vim.loader.reset()
  for _, p in ipairs(patterns) do
    if not p.mod and type(p[1]) == "string" then
      p = { mod = p[1], fn = p.fn }
    end
    local unloaded = false
    for m, _ in pairs(package.loaded) do
      if m:match(p.mod) then
        unloaded = true
        package.loaded[m] = nil
        print(string.format("UNLOADED module '%s'", m))
      end
    end
    if unloaded and p.fn then
      p.fn()
      print(string.format("RELOADED module '%s'", p.mod))
    end
  end
end

M.reload_config = function()
  M.unload_modules({
    { "^core.options$",      fn = function() require("core.options") end },
    { "^core.autocmds$",     fn = function() require("core.autocmds") end },
    { "^core.keymap$",       fn = function() require("core.keymap") end },
    { "^core.utils$",        fn = function() require("core.utils") end },
  })
  -- re-source all language specific settings, scans all runtime files under
  -- '/usr/share/nvim/runtime/(indent|syntax)' and 'after/ftplugin'
  local ft = vim.bo.filetype
  vim.tbl_filter(function(s)
    for _, e in ipairs({ "vim", "lua" }) do
      if ft and #ft > 0 and s:match(("/%s.%s"):format(ft, e)) then
        local file = vim.fn.expand(s:match("[^: ]*$"))
        vim.cmd("source " .. file)
        M.warn("RESOURCED " .. vim.fn.fnamemodify(file, ":."))
        return s
      end
    end
    return false
  end, vim.fn.split(vim.fn.execute("scriptnames"), "\n"))
  -- remove last search highlight
  vim.cmd("nohl")
end

return M
