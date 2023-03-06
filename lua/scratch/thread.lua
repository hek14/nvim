local serialize_util = require('scratch.serialize')
local func = function(p, uv)
  local main_loop_callback
  local start = uv.hrtime()
  main_loop_callback = uv.new_async(vim.schedule_wrap(function(a, b, c)
    p('main_loop_callback started, is_main: ',not vim.is_thread(), uv.hrtime()/1000000)
    uv.close(main_loop_callback)
    p('main_loop_callback ended, spent: ',(uv.hrtime()-start)/1000000)
  end))
  local t = vim.api.nvim_buf_get_lines(0,0,-1,false)
  vim.pretty_print('t_in_main: ',t)
  local t_str = serialize_util.pickle(t)
  local args = {500, 'string', nil, false, 5, "helloworld", t_str, main_loop_callback}
  local unpack = unpack or table.unpack
  local child_thread = uv.new_thread(function(num, s, null, bool, five, hw, t_str, asy)
    --[[
    NOTE: child thread is used to process necessary information needed in main_loop_callback
    any vim.api function is not accessible in the child_thread, because the child_thread is a separate lua interpreter, 
    and it cannot access the vim main loop's state.
    -- ]]

    --[[
    NOTE: the following message may occur later than the main_loop_callback's start message, but it's because
    that the `print` function is implemented in the vim main loop, so the child_thread message will occur in
    the editor's message buffer later.
    --]]
    print('child_thread started, is_child: ',vim.is_thread())

    --[[
    NOTE: child thread event loop, just as the vim's main loop, it's an event loop that has it's own state binded to this
    child_thread
    --]]
    local uv2 = require 'luv'
    --[[
    NOTE: heavy work remains in child thread, it will not block the vim.loop(UI thread)
    --]]
    print('ready to trigger main_loop_callback ',uv2.hrtime()/1000000)

    --[[
    NOTE: awake the main loop's callback function
    --]]
    local serialize_util = require('scratch.serialize')
    local t_in_thread = serialize_util.unpickle(t_str)
    print('t_in_thread',vim.inspect(t_in_thread))
    for i,line in ipairs(t_in_thread) do
      uv2.sleep(100)  -- NOTE: this will not block the main thread
    end
    asy:send('a',true,250) -- or: uv2.async_send(asy, 'a', true, 250)
    print('child_thread ended')
  end, unpack(args))
  --[[
   NOTE: if you call child_thread:join() here, the UI thread will be blocked because it needs to wait the child_thread to finish. 
  that's just what `:join()` mean indeed.
  --]]
  return child_thread
end

local thread = func(print, vim.loop)
-- thread:join() -- NOTE: call join will block the main thread because it has to wait the thread to finish
print('everything is finished')
