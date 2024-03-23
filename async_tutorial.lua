local a = require "async"
local co = coroutine
local uv = vim.loop


--#################### ########### ####################
--#################### Sync Region ####################
--#################### ########### ####################


-- sync version of pong
-- lua是一个single-thread程序, 所以在lua中提到`thread`通常不是指cpu执行的那个thread, 而是指coroutine object, 或者说一个context
-- NOTE: 这个函数的作用是: 一个coroutine通常有很多pausible的checkpoint, pong函数可以unroll一个coroutine object/thread, 让它执行到结束位置, 也就是变成一个非coroutine
local pong = function (thread)
  local nxt = nil
  nxt = function (cont, ...)
    if not cont
      then return ...
      else return nxt(co.resume(thread, ...))
    end
  end
  return nxt(co.resume(thread))
end


local sync_example = function ()

  local thread = co.create(function ()
    local x = co.yield(1)
    print(x)
    local y, z = co.yield(2, 3)
    print(y, z)
    local f = co.yield(4)
    print(f)
  end)

  pong(thread)
end


--#################### ############ ####################
--#################### Async Region ####################
--#################### ############ ####################


-- NOTE: 这里用timeout来模拟一个async op需要经过一段时间之后才能拿到结果, 并调用callback
local timeout = function (ms, callback)
  local timer = uv.new_timer()
  uv.timer_start(timer, ms, 0, function ()
    uv.timer_stop(timer)
    uv.close(timer)
    callback()
  end)
end


-- NOTE: 下面这个函数就是一个典型的async op的样子: 输入两个参数+一个callback function, 它是异步的, 通常代表I/O, network request, database query
-- typical nodejs / luv function
local echo_2 = function (msg1, msg2, callback)
  -- wait 1000ms
  timeout(1000, function ()
    -- NOTE: 代表async op已经处理完得到结果, 这里`callback(msg1, msg2)`相当于`return msg1, msg2;`
    -- 可以任意加工返回任何值: 比如 `callback(2*msg1, 3*msg2)`
    callback(msg1, msg2)
  end)
end


-- NOTE:
-- 对于一个异步操作, 比如上面的echo_2, 如果直接调用它like below:
-- echo_2()
-- print("continue running!")
-- 那么这个"continue running"会直接打印出来, 这是因为echo_2是异步的, non-blocking
-- 所以就得使用`a.wrap`将这个异步op包装成awaitable, 从而允许同步化
-- 使用 `a.wait(e2(input_1, input_2))` 会等待echo_2这个异步op结束, 同步化!
-- echo_2(异步) -> e2(同步)
-- thunkify echo_2
local e2 = a.wrap(echo_2)


local async_tasks_1 = function()
  -- NOTE: 这里 a.sync(function()...end) 就等价于python中`async def xxx`就是定义一个awaitable coroutine
  return a.sync(function ()
    local x, y = a.wait(e2(1, 2)) -- NOTE: 上面说了, await(e2(x, x))是同步的, 同步指的是pause当前的context, 不是block当前cpu thread, 所以在nvim中使用a.wait只会pause当前coroutine, 不会导致编辑器卡顿!
    print(x, y) -- NOTE: 此时已经过去了1000ms, 当前task pause在了此处
    return x + y
  end)
end


local async_tasks_2 = function (val)
  return a.sync(function ()
    -- await all
    -- NOTE: 这里a.await_all等价于python中`asyncio.gather(x,y)`, 也就是说`wait_all`一个batch, batch内部是并发的, 但是后面的语句必须等待整个batch都拿到结果之后才能继续执行.
    local w, z = a.wait_all{e2(val, val + 1), e2(val + 2, val + 3)}
    -- NOTE: 由于wait_all等价于asyncio.gather, batch内部的tasks是并行的, 所以总共只会花1000ms
    print(unpack(w))
    print(unpack(z))
    return function ()
      return 4
    end
  end)
end


local async_example = function ()
  return a.sync(function ()
    -- composable, await other async thunks
    -- NOTE: 这里没使用wait_all, 所以async_tasks_1和async_tasks_2是串行的或者说依次执行的
    -- a.wait(xxx) xxx必须是 a.sync()或者a.wrap() 所wrap的一个function
    local u = a.wait(async_tasks_1())
    local v = a.wait(async_tasks_2(3)) -- NOTE: awaitable返回值可以是任何东西, 这和一般的function一样
    print(u + v())
  end)
end


--#################### ############ ####################
--#################### Loops Region ####################
--#################### ############ ####################


-- avoid textlock
local main_loop = function (f)
  vim.schedule(f)
end


local vim_command = function (args1, args2)
  local str = string.format("echom 'calling vim command with args: %s %s'", args1, args2)
  vim.api.nvim_command(str)
end


local textlock_fail = function()
  return a.sync(function ()
    a.wait(e2(1, 2))
    vim_command()
  end)
end


local textlock_succ = function ()
  return a.sync(function ()
    local x, y = a.wait(e2(1, 2))
    a.wait(main_loop)
    -- NOTE: 在async wrap的函数内部想要调用vim.api必须先a.wait(main_loop)
    vim_command(x, y)
  end)
end

-- NOTE: 最终root节点怎么调用呢: python中是`asyncio.run(root_coroutine)`, 这里是直接root_coroutine()
-- textlock_succ()()


return {
  sync_example = sync_example,
  async_example = async_example,
  textlock_fail = textlock_fail,
  textlock_succ = textlock_succ,
}
