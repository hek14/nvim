local log_path = vim.fn.expand("$HOME") .. "/.cache/nvim/neovim_debug.log"
local M = {}
M.lprint = function(...)
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

M.add_timer = function(fn)
  local function timedFn()
    local wait = fn()
    if wait>0 then
      vim.defer_fn(timedFn, wait)
    end
  end
  timedFn()
end

RELOAD = function(...)
  return require("plenary.reload").reload_module(...)
end

R = function(name)
  RELOAD(name)
  return require(name)
end

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


function _G.my_hack()
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
return M
