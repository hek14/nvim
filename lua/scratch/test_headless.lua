local uv = vim.loop
local log = require('core.utils').log
local sel = require('scratch.serialize')
local function safe_close(handle)
  if not uv.is_closing(handle) then
    uv.close(handle)
  end
end


local group_by_path = function(input)
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
      log('delete the: ',input[i])
      input[i] = nil
    end
  end

  local results = {
    {input[1]}
  } 
  local current_file = input[1].file
  for i,item in ipairs(input) do
    if item.file~=current_file then
      table.insert(results, {item})
      current_file = item.file
    else
      table.insert(results[#results],item)
    end
  end
  return results
end

local M = {
  childs = {},
  data = {},
  done = false,
  current_input = {},
}

function M:kill_all()
  for i, c in ipairs(self.childs) do
    c:kill()
  end
end

function M:send(input)
  local grouped_input = group_by_path(input)
  log("grouped_input: ",grouped_input)
  self.current_input = input
  for i,sub_input in ipairs(grouped_input) do
    self.childs[(i % #self.childs)+1]:send(sub_input)
  end
end

local make_pos_key = function(position)
  return string.format('row:%scol:%s',position[1],position[2])
end

function M:count_results()
  local cnt = 0
  for i,item in ipairs(self.current_input) do
    local pos_key = make_pos_key(item.position)
    if self.data[item.file] and self.data[item.file][pos_key] then
      cnt = cnt + 1
    end
  end
  self.parsed_cnt = cnt
end

function M:with_output(cb)
  local timer = uv.new_timer() 
  timer:start(0,10,vim.schedule_wrap(function()
    for i,c in ipairs(self.childs) do
      self.data = vim.tbl_deep_extend('force',c.data,self.data)
    end
    self:count_results()
    if self.parsed_cnt == #self.current_input then
      self.done = true
      if timer and not timer:is_closing() then
        timer:stop()
        timer:close()
      end
      if cb and type(cb)=='function' then
        cb(self.data)
      end
    else
      self.done = false
    end
  end))
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

function process:send(input)
  log("sub_input: ",input)
  local timer = vim.loop.new_timer()
  timer:start(0,10,vim.schedule_wrap(function ()
    if self.done then
      log("sub_input: ",input)
      self.profile_start = vim.loop.hrtime()
      self.done = false
      local send_input = sel.pickle(input) -- NOTE: input example: /Users/hk/.config/nvim/lua/scratch/a_input_t.lua
      uv.write(self.stdin, send_input)
      log('write end')
      if timer and not timer:is_closing() then
        timer:stop()
        timer:close()
      end
    else
      log('not done yet,should queue')
    end
  end))
end

function M:batch(cnt)
  for i = 1,cnt do 
    self:spawn()
  end
end

function M:spawn()
  local stdin = uv.new_pipe(false)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local handle,pid_or_err
  local opts = {
    args = {'--headless','-u','NORC','--cmd', 'lua require("scratch.ts_util").wait_stdin()'}, -- TODO: --clean, -u, -n, -i
    stdio = { stdin, stdout, stderr },
    cwd = vim.fn.stdpath('config'),
  }

  local on_exit = vim.schedule_wrap(function(code)
    log('should exit now!')
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
      log('before merge: ',child_process.data)
      log('receive new: ',data)
      child_process.data = vim.tbl_deep_extend('force',data,child_process.data)
      log('after merge: ',child_process.data)
      child_process.done = true
      child_process.spent = (vim.loop.hrtime() - child_process.profile_start)/1e6
      log('child_process.spent: ',child_process.spent)
    end
  end))
  log('spawn a background nvim process: ',child_process.pid)
  table.insert(M.childs,child_process)
  return child_process
end

return M
