local uv = vim.loop
local log = require('core.utils').log
local fmt = string.format
local sel = require('scratch.serialize')

local coding_util = require('scratch.stream_coding')

local make_file_pos_key = function(file,position)
  return fmt('file:%s,row:%s,scol:%s',file,position[1],position[2])
end
local make_pos_key = function(position)
  return string.format('row:%s,col:%s',position[1],position[2])
end

local process = {}
process.__index = process
function process:new(stdin,stdout,stderr,handle)
  return setmetatable({
    stdin = stdin,
    stdout = stdout,
    stderr = stderr,
    handle = handle,
    file_pos_to_latest_ticket = {},
    tickets = {}
  },process)
end

-- function process:exit()
--   uv.write(self.stdin, "FINISHED")
-- end

function process:kill()
  uv.kill(self.pid,9)
end

function process:init_ticket(tick,input)
  if self.tickets[tick] then
    log("not possible, the tick is already here? don't call this multiple times")
    return
  end
  self.tickets[tick] = {input = input , output = nil}
end

function process:retrieve(file,position)
  local session_tick = self.file_pos_to_latest_ticket[make_file_pos_key(file,position)] -- don't worry, this is the latest ticket
  if not session_tick then
    return 'not sent'
  end

  if self.tickets[session_tick] and self.tickets[session_tick].output then
    local pos_key = make_pos_key(position)
    return self.tickets[session_tick].output[file][pos_key]
  else
    return "processing"
  end
end

function process:send(input)
  -- NOTE: what is a (send/session) tick? it corresponds a session with the background ts parser
  -- a session is { input = , output = }
  -- with the ticket, you can call send function very frequently, don't worry about lossing anything
  local tick = vim.loop.hrtime()
  for i, item in ipairs(input) do
    local file_pos_key = make_file_pos_key(item.file,item.position)
    if self.file_pos_to_latest_ticket[file_pos_key] and self.file_pos_to_latest_ticket[file_pos_key]~=tick then
      -- log(fmt('update the old ticket %d to newest %d',self.file_pos_to_latest_ticket[file_pos_key],tick))
      -- can do something interesting here: when a file has been requested for multiple times(history ticks), it's hot!
    end
    self.file_pos_to_latest_ticket[file_pos_key] = tick  -- always the latest tick by overriding
  end

  self:init_ticket(tick,input)

  local send_input = coding_util.encoding(input,tick)
  uv.write(self.stdin, send_input)
  return tick
end

function process:done()
  local ticket_cnt = #vim.tbl_keys(self.tickets)
  if ticket_cnt == 0 then return 1 end

  local ticket_done_cnt = 0
  for k,v in pairs(self.tickets) do
    if v.output~=nil then
      ticket_done_cnt = ticket_done_cnt + 1
    end
  end
  return ticket_done_cnt/ticket_cnt
end

function process.on_stdout(p)
  local cb = function (data)
    for tick,ret in pairs(data) do
      tick = tonumber(tick)
      p.tickets[tick].output = ret
    end
  end
  return coding_util.wrap_for_on_stdout(cb)
end


function process.on_err(p)
  return function (err,what)
    if err then
      print(fmt('process: %s failed with: %s, %s',p.pid,err,what))
    end
  end
end

function process.on_exit(p)
  local function safe_close(handle)
    if handle and not uv.is_closing(handle) then
      uv.close(handle)
    end
  end
  return vim.schedule_wrap(function(code)
    uv.read_stop(p.stdout)
    uv.read_stop(p.stderr)
    safe_close(p.handle)
    safe_close(p.stdin)
    safe_close(p.stdout)
    safe_close(p.stderr)
  end)
end


--- M is the manager for multiple child processes
local M = {
  childs = {},
  file_to_child_id = {}
}

function M:spawn()
  local stdin = uv.new_pipe(false)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local handle,pid_or_err
  local opts = {
    args = {'--headless','-u','NORC','-i','NONE','-n','--cmd', 'lua require("scratch.remote_ts_parse").wait_stdin()'},
    stdio = { stdin, stdout, stderr },
    cwd = vim.fn.stdpath('config'),
  }

  local child_process = process:new(stdin,stdout,stderr,handle)
  handle, pid_or_err = uv.spawn("nvim", opts, process.on_exit(child_process))
  child_process.pid = pid_or_err
  uv.read_start(stdout,process.on_stdout(child_process))
  uv.read_start(stderr,process.on_err(child_process))
  table.insert(M.childs,child_process)
  return child_process
end

function M:batch(cnt)
  if #self.childs >= cnt then
    log(fmt("already have %s runing in the background",#self.childs))
    return
  end

  for i = 1,cnt do 
    self:spawn()
  end
end

function M:send(input)
  -- NOTE: make sure that items that belong to the same files sent to the child, this will same some parse time
  local data = {}
  for i = 1,#self.childs do
    data[i] = {}
  end
  local child_index = 1
  for i, item in ipairs(input) do
    if self.file_to_child_id[item.file] then
      table.insert(data[self.file_to_child_id[item.file]],item)
    else
      self.file_to_child_id[item.file] = child_index
      table.insert(data[child_index],item)
      if child_index + 1 <= #self.childs then
        child_index = child_index + 1
      else
        child_index = 1
      end
    end
  end

  local index = {}
  local total_data_cnt = 0
  for i = 1,#self.childs do
    index[i] = 1
    total_data_cnt = total_data_cnt + #data[i]
  end
  local max_batch = 50

  local all_sent = 0
  while all_sent < total_data_cnt do
    for i = 1,#self.childs do
      if index[i] <= #data[i] then
        local batch = vim.list_slice(data[i], index[i], index[i]+max_batch-1)
        index[i] = index[i] + max_batch
        if #batch > 0 then
          -- log(fmt("child %s sent %s|%s",i,index[i]-1,#data[i]))
          self.childs[i]:send(batch)
          all_sent = all_sent + #batch
        end
      end
    end
  end
  local timer = vim.loop.new_timer()
  local start = vim.loop.hrtime()
  local running = true
  timer:start(30,50,function()
    if not running then return end

    local now = vim.loop.hrtime()
    local done = self:done()
    if done and not timer:is_closing() then
      timer:stop()
      timer:close()
      running = false
      log(fmt('[bridge_ts_parser]: %d items already done after: %dms ',#input,(now-start)/1e6))
    else
      if (now-start)/1e6 > 300 then
        log(fmt('[bridge_ts_parser]: not done yet even after %dms',(now-start)/1e6))
      end
    end
  end)
  -- log('all sent: ',all_sent,'total todo: ',total_data_cnt)
end

function M:retrieve(file,position)
  -- NOTE: this function can be used async: it's alright if the parse result is not already 
  local child = self.childs[self.file_to_child_id[file]]
  if not child then return 'no child' end
  return child:retrieve(file,position)
end

function M:kill_all()
  for i, c in ipairs(self.childs) do
    c:kill()
  end
end

function M:done()
  local cnt = 0
  for i, c in ipairs(self.childs) do
    cnt = cnt + c:done()
  end
  return cnt == #self.childs, cnt/#self.childs
end

function M:with_output(cb,ratio)
  local timer = uv.new_timer() -- start a new timer to check if done
  local running = true
  timer:start(0,10,vim.schedule_wrap(function()
    if not running then return end
    local done,done_ratio
    if not ratio then
      done = self:done()
    else
      _, done_ratio = self:done()
      done = done_ratio > ratio
    end
    if done then
      cb(ratio and done_ratio or done)
      if not timer:is_closing() then
        running = false
        timer:stop()
        timer:close()
      end
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


vim.api.nvim_create_autocmd('VimLeavePre',{
  callback = function ()
    require('scratch.bridge_ts_parse'):kill_all()
  end
})

return M
