local M = {}
local uv = vim.loop
local function safe_close(handle)
  if not uv.is_closing(handle) then
    uv.close(handle)
  end
end
local states = {}
local start
M.files = {}
local function exe(cmd,cmd_opts,cwd)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local handle,pid_or_err
  local other_err = false
  local opts = {
    args = cmd_opts,
    stdio = { nil, stdout, stderr },
    cwd = cwd
  }
  handle, pid_or_err = uv.spawn(cmd, opts, function(code)
    uv.read_stop(stdout)
    uv.read_stop(stderr)
    safe_close(handle)
    safe_close(stdout)
    safe_close(stderr)
    print(string.format('spent time: %s ms',(vim.loop.hrtime()-start)/1000000))
  end)
  uv.read_start(stderr, function(err, data)
    assert(not err, err)
  end)
  uv.read_start(stdout, function(err, data)
    if data then
      local paths = vim.split(data,'\n')
      for _,p in ipairs(paths) do
        if #p>0 then
          table.insert(M.files[cmd_opts[2]],p)
        end
      end
    end
  end)
end


M.find = function(file)
  start = vim.loop.hrtime()
  M.files[file] = {}
  exe('fd',{'-p',file},vim.fn.getcwd()) 
  return M
end

return M
