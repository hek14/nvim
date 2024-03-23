---------- NOTE: how to use this job_util
-- local M = require("scratch.job_util")
-- local t = M:new([[ssh qingdao 'cd ~/codes_med33/CHI2024; fd --no-ignore ".*"']], function(out, err)
--   M:dump_to_file("~/log2", out)
-- end)
-- t:run()

local M = {}
function M:new(cmd, exit_hook)
  local instance = {
    cmd = cmd,
    sorted = false,
    std_out = {},
    std_err = {},
    begin_time = nil,
    end_time = nil,
    exit_hook = exit_hook,
  }
  setmetatable(instance, self)
  self.__index = self
  return instance
end

local f = string.format

function M:dump_to_file(filename, content)
  filename = vim.fn.expand(filename)
  local file = io.open(filename, "w")
  if file then
    for _, str in ipairs(content) do
      file:write(str .. "\n")
    end
    file:close() -- Close the file
    vim.notify(f("Stdout saved to file: %s", filename), vim.log.levels.INFO)
  else
    vim.notify(f("Failed to open file: %s", filename), vim.log.levels.ERROR)
  end
end

function M:on_stdout()
  return function(job_id, data, event)
    for e, item in ipairs(data) do
      table.insert(self.std_out, item)
    end
  end
end

local is_empty = function(e)
  return e == nil or #e == 0
end

local is_not_empty = function(e)
  return not is_empty(e)
end

function M:on_stderr()
  return function(job_id, data, event)
    for e, item in ipairs(data) do
      table.insert(self.std_err, item)
    end
  end
end

function M:on_exit()
  return function(job_id, err, event)
    self.end_time = vim.loop.hrtime()
    vim.notify(f("cmd spent: %s seconds", (self.end_time - self.begin_time)/1000000000), vim.log.levels.INFO)
    self.std_out = vim.tbl_filter(is_not_empty, self.std_out)
    self.std_err = vim.tbl_filter(is_not_empty, self.std_err)
    if #self.std_out == 0 then
      self.std_out = nil
    end
    if #self.std_err == 0 then
      self.std_err = nil
    end
    if self.sorted and type(self.std_out) == "table" then
      table.sort(self.std_out)
    end
    if self.exit_hook then
      self.exit_hook(self.std_out, self.std_err)
    end
  end
end

function M:run()
  -- vim.cmd(f("echo 'Run %s'", self.cmd))
  self.begin_time = vim.loop.hrtime()
  vim.fn.jobstart(self.cmd, {
    on_stderr = self:on_stderr(), on_stdout = self:on_stdout(), on_exit = self:on_exit(), stdout_bufferd = true
  })
end

return M
