-- refer to: https://www.youtube.com/watch?v=W8Mq--dqNow&ab_channel=YukiUthman
local uv = vim.loop

local start_time = uv.uptime()

local data = {1,3,3,5}
local found = 1
local test = function()
  print('test')
  table.sort(data)
  print(data)
  found = 3
end

local function work(id,start_time,sleep_time,test)
  local uv = vim.loop
  print(string.format('work %s start at: %s, PID: %s',id,start_time, uv.os_getpid()))
  uv.sleep(sleep_time)
  print(string.format('work %s end at: %s',id,uv.uptime()))
  print(vim.api.nvim_get_current_buf())
  return id
end

local function done(id)
  print(string.format('work %s done, %s',id, uv.os_getpid()))
end

local ctx = uv.new_work(work,done)

uv.queue_work(ctx,1,start_time,100*1000)
uv.queue_work(ctx,2,start_time,10*1000)
uv.queue_work(ctx,3,start_time,20*1000)
uv.queue_work(ctx,4,start_time,30*1000)
