local uv = vim.loop
local log = require('core.utils').log
local sel = require('scratch.serialize')
local function safe_close(handle)
  if not uv.is_closing(handle) then
    uv.close(handle)
  end
end

local M = {
  childs = {},
  data = {},
  done = false,
  last_request = vim.loop.hrtime(),
  current_input = {},
}

local make_pos_key = function(position)
  return string.format('row:%scol:%s',position[1],position[2])
end

function M:count()
  local cnt = 0
  for i,item in ipairs(self.current_input) do 
    for i,c in ipairs(self.childs) do
      if c.data[item.file] and c.data[item.file][make_pos_key(item.position)] then
        cnt = cnt + 1
        break
      end
    end
  end
  return cnt
end

local expand_tbl = function (t1,t2)
  for j,d in ipairs(t2) do
    t1[#t1+1] = d
  end
  return t1
end

function M:send(input)
  local now = vim.loop.hrtime()
  if (now-self.last_request)/1e6<0.1 then -- the interval of two request less than 0.1
    self.current_input = expand_tbl(self.current_input,input)
  else
    self.current_input = input
  end

  table.sort(input,function(a,b)
    return a.file < b.file
  end)
  -- NOTE: filter the non-exist path
  local index = 1
  for i,item in ipairs(input) do
    if vim.loop.fs_stat(item.file) then
      input[index] = item
      index = index + 1
    end
  end

  if index == 1 then
    return {}
  else
    for i = index,#input do
      input[i] = nil
    end
  end

  local results = {{input[1]}} 
  local current_file = input[1].file
  for i=2,#input do
    local item = input[i]
    if item.file~=current_file then
      table.insert(results, {item})
      current_file = item.file
    else
      table.insert(results[#results],item)
    end
  end

  local child_index = 1
  for i,g in ipairs(results) do
    local c_file = g[1].file
    local handled = false
    for k,c in ipairs(self.childs) do
      if c.data[c_file] then
        log("some child has handle this before ",c_file,'you: ',k)
        c:send(g)
        handled = true
        break
      end
    end
    if not handled then
      log("nobody handle this yet: ",c_file,'you: ',child_index)
      self.childs[child_index]:send(g)
      child_index = (child_index + 1)<=#self.childs and child_index + 1 or 1
    end
  end
  self.last_request = vim.loop.hrtime()
  return results
end

function M:kill_all()
  for i, c in ipairs(self.childs) do
    c:kill()
  end
end

function M:batch(cnt)
  for i = 1,cnt do 
    self:spawn()
  end
end


function M:with_output(cb)
  local timer = uv.new_timer() 
  local running = true
  timer:start(0,10,vim.schedule_wrap(function()
    local cnt = self:count()
    if cnt == #self.current_input then
      self.done = true
      for i,c in ipairs(self.childs) do
        self.data = vim.tbl_deep_extend('force',c.data,self.data)
      end
      if running and cb and type(cb)=='function' then
        cb(self.data)
      end
      if not timer:is_closing() then
        running = false
        timer:stop()
        timer:close()
      end
    else
      self.done = false
    end
  end))
  local cancel = function ()
    running = false
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end
  return cancel -- NOTE: just like lsp buf_request return value, you can cancel the cb call using `cancel`
end

local process = {}
process.__index = process
function process:new(pid,stdin,stdout)
  return setmetatable({
    pid = pid,
    stdin = stdin,
    stdout = stdout,

    profile_start = vim.loop.hrtime(),
    done = true, -- NOTE: should init to true for process:send() to start at the first time
    data = {},
    spent = -1
  },process)
end

function process:exit()
  uv.write(self.stdin, "FINISHED")
end

function process:kill()
  uv.kill(self.pid,9)
end

function process:with_output(cb)
  local timer = vim.loop.new_timer()
  timer:start(0,10,vim.schedule_wrap(function ()
    if self.done then
      cb(self.data)
      if timer and not timer:is_closing() then
        timer:stop()
        timer:close()
      end
    end
  end))
end

function process:send(input)
  local timer = vim.loop.new_timer()
  timer:start(0,5,vim.schedule_wrap(function ()
    if self.done then
      self.profile_start = vim.loop.hrtime()
      self.done = false
      local send_input = sel.pickle(input) -- NOTE: input example: /Users/hk/.config/nvim/lua/scratch/a_input_t.lua
      uv.write(self.stdin, send_input)
      if timer and not timer:is_closing() then
        timer:stop()
        timer:close()
      end
    else
      log('not done yet,should queue')
    end
  end))
end


function M:spawn()
  local stdin = uv.new_pipe(false)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local handle,pid_or_err
  local opts = {
    args = {'--headless','-u','NORC','-i','NONE','-n','--cmd', 'lua require("scratch.ts_util").wait_stdin()'},
    stdio = { stdin, stdout, stderr },
    cwd = vim.fn.stdpath('config'),
  }

  local on_exit = vim.schedule_wrap(function(code)
    uv.read_stop(stdout)
    uv.read_stop(stderr)
    safe_close(handle)
    safe_close(stdin)
    safe_close(stdout)
    safe_close(stderr)
  end)
  handle, pid_or_err = uv.spawn("nvim", opts, on_exit)

  local child_process = process:new(pid_or_err,stdin,stdout)
  uv.read_start(stderr, function(err, data)
    assert(not err, err)
  end)
  uv.read_start(stdout, vim.schedule_wrap(function(err, data)
    assert(not err,err)
    if data then
      data = sel.unpickle(data)
      -- child_process.data = data
      child_process.data = vim.tbl_deep_extend('force',data,child_process.data)
      child_process.done = true
      child_process.spent = (vim.loop.hrtime() - child_process.profile_start)/1e6
    end
  end))
  table.insert(M.childs,child_process)
  return child_process
end

return M
