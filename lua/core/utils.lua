local M = {}

local cmd = vim.cmd
M.close_buffer = function(force)
  if vim.bo.buftype == "terminal" then
    vim.api.nvim_win_hide(0)
    return
  end

  local fileExists = vim.fn.filereadable(vim.fn.expand "%p")
  local modified = vim.api.nvim_buf_get_option(vim.fn.bufnr(), "modified")

  -- if file doesnt exist & its modified
  if fileExists == 0 and modified then
    print "no file name? add it now!"
    return
  end

  force = force or not vim.bo.buflisted or vim.bo.buftype == "nofile"

  -- if not force, change to prev buf and then close current
  -- local close_cmd = force and ":bd!" or ":e #| bd" .. vim.fn.bufnr()
  local close_cmd = force and ":bd!" or ":bp | bd" .. vim.fn.bufnr()
  vim.cmd(close_cmd)
end

-- hide statusline
-- tables fetched from load_config function
M.hide_statusline = function()
  local hidden = require("core.utils").load_config().plugins.options.statusline.hidden
  local shown = require("core.utils").load_config().plugins.options.statusline.shown
  local api = vim.api
  local buftype = api.nvim_buf_get_option(0, "ft")

  -- shown table from config has the highest priority
  if vim.tbl_contains(shown, buftype) then
    api.nvim_set_option("laststatus", 2)
    return
  end

  if vim.tbl_contains(hidden, buftype) then
    api.nvim_set_option("laststatus", 0)
    return
  end

  api.nvim_set_option("laststatus", 2)
end

M.load_config = function()
  local conf = require "core.default_config"
  return conf
end

M.map = function(mode, keys, command, opt)
  local options = { noremap = true, silent = true }
  if opt then
    options = vim.tbl_extend("force", options, opt)
  end

  -- all valid modes allowed for mappings
  -- :h map-modes
  local valid_modes = {
    [""] = true,
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
  local function map_wrapper(sub_mode, lhs, rhs, sub_options)
    if type(lhs) == "table" then
      for _, key in ipairs(lhs) do
        map_wrapper(sub_mode, key, rhs, sub_options)
      end
    else
      if type(sub_mode) == "table" then
        for _, m in ipairs(sub_mode) do
          map_wrapper(m, lhs, rhs, sub_options)
        end
      else
        if valid_modes[sub_mode] and lhs and rhs then
          if vim.fn.has("nvim-0.7")>0 then
            vim.keymap.set(sub_mode, lhs, rhs, sub_options)
          else
            vim.api.nvim_set_keymap(sub_mode, lhs, rhs, sub_options)
          end
        else
          sub_mode, lhs, rhs = sub_mode or "", lhs or "", rhs or ""
          print(
            "Cannot set mapping [ mode = '" .. sub_mode .. "' | key = '" .. lhs .. "' | cmd = '" .. rhs .. "' ]"
          )
        end
      end
    end
  end

  map_wrapper(mode, keys, command, options)
end

-- load plugin after entering vim ui
M.packer_lazy_load = function(plugin, timer)
  if plugin then
    timer = timer or 0
    vim.defer_fn(function()
      require("packer").loader(plugin)
    end, timer)
  end
end

-- Highlights functions

-- Define bg color
-- @param group Group
-- @param color Color

M.bg = function(group, col)
  cmd("hi " .. group .. " guibg=" .. col)
end

-- Define fg color
-- @param group Group
-- @param color Color
M.fg = function(group, col)
  cmd("hi " .. group .. " guifg=" .. col)
end

-- Define bg and fg color
-- @param group Group
-- @param fgcol Fg Color
-- @param bgcol Bg Color
M.fg_bg = function(group, fgcol, bgcol)
  cmd("hi " .. group .. " guifg=" .. fgcol .. " guibg=" .. bgcol)
end


--provide labels to plugins instead of integers
M.label_plugins = function(plugins)
  local plugins_labeled = {}
  for _, plugin in ipairs(plugins) do
    plugins_labeled[plugin[1]] = plugin
  end
  return plugins_labeled
end


-- clear command line from lua
M.clear_cmdline = function()
  vim.defer_fn(function()
    vim.cmd "echo"
  end, 0)
end

-- wrapper to use vim.api.nvim_echo
-- table of {string, highlight}
-- e.g echo({{"Hello", "Title"}, {"World"}})
M.echo = function(opts)
  if opts == nil or type(opts) ~= "table" then
    return
  end
  vim.api.nvim_echo(opts, false, {})
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

M.reload_plugin = function(plugins)
  local status = true
  local function _reload_plugin(plugin)
    local loaded = package.loaded[plugin]
    if loaded then
      package.loaded[plugin] = nil
    end
    local ok, err = pcall(require, plugin)
    if not ok then
      print("Error: Cannot load " .. plugin .. " plugin!\n" .. err .. "\n")
      status = false
    end
  end

  if type(plugins) == "string" then
    _reload_plugin(plugins)
  elseif type(plugins) == "table" then
    for _, plugin in ipairs(plugins) do
      _reload_plugin(plugin)
    end
  end
  return status
end


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

function _G.stringSplit(inputstr, sep) 
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


function _G.my_hack_undo_redo()
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
        top = "TimeTravel",
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

M.log = function(...)
  local log_path = vim.fn.expand("$HOME") .. "/.cache/nvim/neovim_debug.log"
  local arg = {...}
  local str = "שׁ "
  local lineinfo = ''

  local info = debug.getinfo(2, "Sl")
  lineinfo = info.short_src .. ":" .. info.currentline
  str = str .. lineinfo

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
      io.output(f)
      io.write(str .. "\n")
      io.close(f)
    else
      print(str .. "\n")
    end
  end
end

M.source_curr_file = function()
  if vim.bo.ft == "lua" then
    vim.cmd [[luafile %]]
  elseif vim.bo.ft == "vim" then
    vim.cmd [[so %]]
  end
end


M.smart_current_dir = function()
  local fname = vim.api.nvim_buf_get_name(0)
  local dir = require('lspconfig').util.find_git_ancestor(fname) or
  vim.fn.expand('%:p:h')
  vim.cmd("cd " .. dir)
end


M.closing_float_window = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(win)
        if config.relative ~= "" then
            vim.api.nvim_win_close(win, false)
            print('Closing window', win)
        end
    end
end

M.my_print = function (...)
    local objects = {}
    for i = 1, select('#', ...) do
        local v = select(i, ...)
        table.insert(objects, vim.inspect(v))
    end

    print(table.concat(objects, '\n'))
    return ...
end

vim.cmd [[
  function! Inc(...)
    let result = g:i
    let g:i += a:0 > 0 ? a:1 : 1
    return result
  endfunction
]]

return M
