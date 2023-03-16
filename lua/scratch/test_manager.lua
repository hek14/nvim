-- NOTE: this is a usage example of remote_ts_parse and bridge_ts_parse
local print = vim.pretty_print
local t = require('scratch.large_input_t')
local t2 = require('scratch.two_input_t')
local t3 = require('scratch.a_input_t')
manager = require('scratch.bridge_ts_parse')
manager:batch(3)

local start = vim.loop.hrtime()
manager:send(t)
manager:send(t2)
manager:send(t3)


local timer = vim.loop.new_timer()
local start = vim.loop.hrtime()
local input = {
  {file = '/Users/hk/.config/nvim/lua/scratch/ts_util.lua',position = {345,23}},
  {file = '/Users/hk/.config/nvim/lua/contrib/pig.lua',position = {162,32}},
  {
    file = '/Users/hk/server_files/qingdao/test/debug.py',
    position = {63,31},
  },
}

-- timer:start(5,10,vim.schedule_wrap(function ()
--   print(manager:done())
--
--   for i, item in ipairs(input) do
--     print(manager:retrieve(item.file,item.position))
--   end
--
--   local now = vim.loop.hrtime()
--   if (now - start)/1e6 > 200 then
--     if timer and not timer:is_closing() then
--       timer:stop()
--       timer:close()
--     end
--   end
-- end))
--

manager:with_output(function ()
  print(string.format('spent time: %s ms',(vim.loop.hrtime()-start)/1000000)) 
  for i, item in ipairs(input) do
    print(manager:retrieve(item.file,item.position))
  end
end)
