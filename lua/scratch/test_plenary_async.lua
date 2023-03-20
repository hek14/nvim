local co = coroutine
local async = require('plenary.async')

local x,y,z

local wrap1 = async.wrap(function(a,b,c,callback) -- NOTE: for latter notes, we call this function `be_wrapped` func
  -- NOTE: when we call wrap1(...) if the length of ... is equal to argc(here is 4), then this function will be called just in the current coroutine
  -- if we called wrap1(...) with three args(given a,b,c), then this `be_wrapped` function will be called in the main coroutine(nil)
  -- and the callback is set to `step`(in execute funciton)
  x = a  
  y = b
  z = c
  if not co.running() then
    print("run wrap1 in main!")
  else
    print("run wrap1 in coroutine! ",co.running())
  end
  callback()
end,4)


local wrap2 = async.wrap(function(callback)
  if not co.running() then
    print("run wrap2 in main!")
  else
    print("run wrap2 in coroutine! ",co.running())
  end
  callback()
end,1)

local void = async.void(function(args)
  local context = co.running()
  print('coroutine create: ',context)
  local a,b,c = unpack({4,5,6})
  print('should be called in main')
  wrap1(a,b,c) -- call wrap1 with only 3 args(argc=4), so this will yield out and suspend the `void` coroutine, `be_wrapped` will be called in the main
  print("coroutine continue because of the step")
  wrap2()
  wrap1(7,8,9,function () -- call wrap1 with 4 args(argc==nargs), so this will be called right here, just in the coroutine
    print('this time, should be in co',context,co.running())
  end)
end)

void({'hello','world'}) -- call `execute` function in async.lua
print(x,y,z)
