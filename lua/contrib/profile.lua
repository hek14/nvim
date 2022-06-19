local profiler = {}

profiler.new = function(self)
  local object = {}
  setmetatable(object,self)
  self.__index = self
  return object
end

profiler.start = function(self)
  self.calls = {}
  self.total = {}
  self.this = {}
  debug.sethook(function(event)
    local i = debug.getinfo(2, "Sln")
    if i.what ~= 'Lua' or i.name=="start" or i.name=="stop" then return end
    local func = i.name or (i.source..':'..i.linedefined)
    if event == 'call' then
      self.this[func] = os.clock()
    else
      local time = os.clock() - self.this[func]
      self.total[func] = (self.total[func] or 0) + time
      self.calls[func] = (self.calls[func] or 0) + 1
    end
  end, "cr")
end

profiler.stop = function ()
  debug.sethook()
end

profiler.report = function (self)
  for f,time in pairs(self.total) do
    print(("Function %s took %.3f seconds after %d calls"):format(f, time, self.calls[f]))
  end
end

return profiler
-- the code to debug starts here
-- show case: how to use it:
-- local function DoSomethingMore(x)
--   x = x / 2
-- end
--
-- local function DoSomething(x)
--   x = x + 1
--   if x % 2 then DoSomethingMore(x) end
-- end
--
-- profiler1 = profiler:new()
-- profiler1:start()
-- for i=1,100 do
--   DoSomething(i)
-- end
-- profiler1:stop()
-- profiler1:report()
