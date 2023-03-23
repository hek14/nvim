local log = require('core.utils').log
local running = false
local debounce = 100
local last_called
local function frequent_func(id)
  print(id,running,vim.loop.now())
  if not running then
    running = true
    local timer = vim.loop.new_timer()
    timer:start(debounce,0,vim.schedule_wrap(function()
      running = false -- NOTE:running will remain true for 100ms
      -- print('should reset running?',running,vim.loop.now())
      if last_called then
        local now = vim.loop.hrtime()
        print('called after: ',(now-last_called)/1e6)
        last_called = now
      else
        last_called = vim.loop.hrtime()
      end
    end))
  end
end

--[[
-- 1. use vim.wait/vim.loop.sleep() to block the main loop
-- this will call the frequent_func strictly with a interval of 10ms with no schedule
-- which means the frequent_func is called exactly at 0, 10, 20, 30,..., 
-- 所以i=1的调用将会block掉后面至少9个frequent_func的调用
--]]
-- for i=1,100 do
--   frequent_func(i)
--   vim.wait(10,function ()
--     return false
--   end)
-- end


--[[
-- 2. use defer_fn to schedule frequent_func
-- 注意defer_fn挂勾子有一个相对谁作为时间起始点的问题: 是相对于`vim.defer_fn`被调用的时间点作为起点
-- defer_fn能够保证的是: 优先执行完当前语境下的语句, 不管defer_fn写在多么开头的地方
-- 不能保证的是level靠前的defer_fn一定执行在前面, 只要是defer_fn的task, 它们都是schedule在特点的时间的, 它们之间是平等的
-- 它们之间的唯一原则就是看 起始时间+defer的量
-- 想象一颗树: level 1_1下面有2_1和2_2, 同时1_1 还有兄弟: 1_2, 不能保证level 1_2一定比 level 2_1/2_2 先执行
-- 它们之前完全看相对的时间起点+defer的量计算出来的绝对时间点.
-- 如果defer的量都是0, 那么肯定是level低的先执行, 毕竟level低的挂勾子时的起始点更早. 
-- 就算defer都是0, 算出来的main loop绝对时间点也是更早的, 这个不违背之前说的唯一原则
-- 这一点看: ~/.config/nvim/lua/scratch/defer_fn.lua
-- defer_fn的另外一个特点是: 过期的defer_fn会被一股溜执行, 不会再保持彼此之间的interval, 只会保持先后顺序
--
-- 在这里, 6个`vim.defer_fn(xxx)`可以认为是相对于同一个时间起点
-- 由于vim.loop.sleep(200)先被执行, main loop +200之后发现前四个deferred task都已经outdated, 那么它们会被一股脑扔出去
-- 导致(2,4,3,5) (注意4在3前面) 都被1block了, 如果不是这个sleep(200), 那么5是不会被block的(可以注释掉vim.loop.sleep查看)
--]]
-- vim.defer_fn(function() frequent_func(1) end,10)
-- vim.defer_fn(function() frequent_func(2) end,20)
-- vim.defer_fn(function() frequent_func(3) end,50)
-- vim.defer_fn(function() frequent_func(4) end,30)
-- vim.defer_fn(function() frequent_func(5) end,150)
-- vim.defer_fn(function() frequent_func(6) end,400)
-- vim.loop.sleep(200)


--[[
-- 3. this is a really confusing example
-- 这个例子需要画一根时间轴, 首先(0,1,...20)勾子的起始点就是不同的, 它们各自相差200ms
-- 它们的起始点分别是: (0,200,400,...,3800,4000)
-- 然后它们defer的量分别是: (0, 20, 40, ..., 380, 400)
-- 在4000ms的时候, 当前context结束, 正式开始check deferred tasks, 这是一个关键点: 何时完成当前context开始check勾子
-- 要注意的是: 这个4000只是理论值
-- 此时main loop发现(0-18)号勾子都过时了, 以18为例, 它的起点是3600, defer的量是360, 所以绝对点是3960, 那么4000check的时候
-- 它就过期了
-- 所以跟前面一个例子一样, 它们会被一股脑执行, 忽略原本20的interval, 那么(1-18)都会被0 block掉
-- 19起始点是3800, 加上defer的量380, 绝对点是4180, 它在4000ms被check时没有过期, 所以正常执行, 且0号task在(4000+100=4100)ms时
-- 释放了running, 那么19号可以正常执行. 20号因为绝对时间点和19号隔了(200+20=220)ms, 所以它也会执行
-- 实际运行还需要考虑到执行成本以及main loop需要干其他的事情, 所以执行的绝对时间点一般都会晚于schedule的点
--]]
-- print('start point: ',vim.loop.now())
-- for i = 0,20 do
--   vim.defer_fn(function ()
--     frequent_func(i)
--   end,i*20)
--   vim.loop.sleep(200)
-- end


--[[
-- 4. 这里因为system命令会block 500ms, 所以导致500ms check勾子的时候所有的勾子都过期了. 都一块执行
-- 导致只有0执行, 其他都被0 block 了
--]]
-- for i = 0,20 do
--   vim.defer_fn(function ()
--     frequent_func(i)
--   end,i*20)
-- end
-- vim.fn.system('sleep 0.5')


--[[
-- 5. this is another really confusing example
-- 如果使用print语句, 因为20条print一块执行会弹出命令行的确认('Press Enter or type command to continue')
-- main loop需要等待用户确认会一直block, 所以开始check勾子的点也被推迟, 导致所有的勾子过期, 出现了类似上一个例子的效果
-- 如果把print语句去掉或者使用log函数, 那么main loop不会block, 开始check勾子的点可以认为是0, 从而一切正常, 0会block 1-5,
-- 6开始正常执行, 6又会block 7-11
--]]
-- for i = 1,20 do
--   print(string.format('schedule_wrap at: %d',vim.loop.now()))
--   -- log(string.format('schedule_wrap at: %d',vim.loop.now()))
--   vim.defer_fn(function ()
--     frequent_func(i)
--   end,i*20)
-- end
