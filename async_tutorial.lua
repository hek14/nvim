local a = require "async"
local co = coroutine
local uv = vim.loop


--#################### ########### ####################
--#################### Sync Region ####################
--#################### ########### ####################


-- unroll a coroutine
-- NOTE: 这个函数的作用是: 一个coroutine通常有很多pausible的checkpoint, pong函数可以unroll一个coroutine, 让它执行到返回最终值为止
local pong = function (thread) -- lua是一个single-thread程序, 所以在lua中提到`thread`通常不是指cpu执行的那个thread, 而是指coroutine, 或者说一个context
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
    return 4
  end)

  print(pong(thread))
end


--#################### ############ ####################
--#################### Async Region ####################
--#################### ############ ####################

-- NOTE: 典型的需要异步的情形有三种：network request, file IO, database query，特点是CPU通常需要等待其他resources返回结果，CPU存在闲置，此时需要异步让CPU执行其他人物以提高CPU利用率
-- NOTE: 这里用timeout来模拟一个async op: 需要经过一段时间之后才能拿到结果, 拿到结果时调用callback
local timeout = function (ms, callback)
  local timer = uv.new_timer()
  assert(timer)
  uv.timer_start(timer, ms, 0, function ()
    if timer then
      uv.timer_stop(timer)
      uv.close(timer)
    end
    callback()
  end)
end


-- NOTE: a.wrap一个function, 通常这个function是异步的, 像timer/job/lsp/其他luv读写文件等函数, a.wrap让其变成一个awaitable
-- 这个function的signature最后一个参数始终是固定的: callback, 这个callback函数用于yield值出去返回给调用a.wait的caller
-- 这个function的其他参数, 比如下面的input_1, input_2则是通过后面`a.wait(e2(1, 2))`来赋值
-- typical nodejs / luv function
local e2 = a.wrap(function (input_1, input_2, callback)
  timeout(500, function ()
    -- 此时async op已经拿到结果, 这里`callback(xxx)`相当于`yield xxx`
    -- 可以任意加工返回任何值: 比如 `callback(2*msg1, 3*msg2)`, 这只是模拟
    callback(input_1*2, input_2*2)
  end)
end)


-- NOTE:这里给出wrap lsp request的例子, 使得它变成awaitable
-- awaitable的特点是不会block整个editor threading, 但是会pause调用a.wait的那个coroutine
local lsp_sync_but_not_blocking = a.wrap(function(callback) -- 可以输入其他参数, 但是callback一定是最后一个
  local buf = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_position_params()
  params.context = {}
  vim.lsp.buf_request(buf, "textDocument/references", params, function(err, result, ctx, config) -- 这个callback的signature原本是怎样就怎样写, 根据具体的async op的规定来
    if(err or result == nil or vim.tbl_isempty(result)) then
      callback("error") -- 相当于yield "error"
    else
      callback(result) -- 相当于yield result
    end
  end)
end)


-- NOTE: 这里给出external shell job的例子, 使得它变成awaitable
local job_sync_but_not_blocking = a.wrap(function(args, callback) -- signature中, 前面随意, 最后一个一定是callback
  local M = require("scratch.job_util")
  local t = M:new([[echo "hello world!"]], function(out, err) -- NOTE: 此处是job_util这个async op定义的callback signature
    table.insert(out, args)
    callback(out)
  end)
  t:run()
end)

-- NOTE: 这里 a.sync(function()...end) 就等价于python中`async def xxx`就是定义一个awaitable coroutine
local async_tasks_1 = a.sync(function ()
  local x, y = a.wait(e2(1, 2))
  -- NOTE:后面的语句一定要等到e2完成, x和y拿到结果之后才能执行, e2暂停, 回到async_tasks_1
  -- async_tasks_1 task queue中并没有其他alternative task, 所以async_tasks_1也会暂停, 于是会回溯到async_tasks_1的caller
  -- 一直回溯没关系, 最外层一定有一个task可以做, 那就是vim main_loop, 所以不管怎么样都不会block整个editor threading
  print(x, y) -- NOTE: 此时已经过去了1000ms
  return x + y
end)


-- NOTE:a.wrap()创建的awaitable后续调用时能够传参
-- 但是a.sync()创建的awaitable后续不能传参数, 其wait语法为: a.wait(coroutine_defined_by_async)
-- 想要传参, 就只能弄一个function, 搞closure, 像下面这样
local task_closure = function (val)
  return a.sync(function () -- NOTE: 这个函数没法带参, 带参数也没法传入
    -- NOTE: 这里a.await_all等价于python中`asyncio.gather(x,y)`, 也就是说`wait_all`一个batch
    -- 一个batch的task之间是并发的, 但是`a.wait_all`后面的语句必须等待整个batch都拿到结果之后才能继续执行
    local w, z = a.wait_all{e2(val, val + 1), e2(val + 2, val + 3)}
    -- NOTE: 由于wait_all等价于asyncio.gather, batch内部的tasks是并行的, 所以总共只会花一份e2的时间
    print(unpack(w))
    print(unpack(z))
    return function ()
      return 4
    end
  end)
end


local main_loop = function(f)
  vim.schedule(f)
end


local async_example = a.sync(function ()
  -- NOTE:async是可以组合的, 跟python中一样, 在一个async内部可以await其他sync, 一直嵌套, 最终最基础的awaitable叶子节点一定是a.wrap
  local u = a.wait(async_tasks_1)
  local v = a.wait(task_closure(3))
  a.wait(main_loop) -- NOTE: 如果要执行api操作, 那么需要schedule main_loop
  local my = a.wait(lsp_sync_but_not_blocking())
  local my2 = a.wait(job_sync_but_not_blocking("Yeah!"))
  print(u + v())
  print("my is: ", vim.inspect(my))
  print("my2 is: ", vim.inspect(my2))
end)


--#################### ############ ####################
--#################### Loops Region ####################
--#################### ############ ####################


-- avoid textlock
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

-- NOTE: 一定要注意: await一定只能用在a.sync wrap的function中, 不能直接用于普通的function中, 更不能直接在文件中写`a.wait(async_example())`, 这和python `await`一样.
local test = a.sync(function()
  a.wait(async_example)
end)
-- NOTE: 最终root节点怎么调用呢: python中是`asyncio.run(root_coroutine)`, 这里是直接root_coroutine()
test()

return {
  sync_example = sync_example,
  async_example = async_example,
  textlock_fail = textlock_fail,
  textlock_succ = textlock_succ,
}
