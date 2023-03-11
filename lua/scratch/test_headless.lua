local uv = vim.loop
local sel = require('scratch.serialize')
local function safe_close(handle)
  if not uv.is_closing(handle) then
    uv.close(handle)
  end
end

local M = {
  data = nil,
  done = false,
}

function M:exe(input)
  self.done = false 
  local start = vim.loop.hrtime()
  local stdin = uv.new_pipe(false)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local handle,pid_or_err
  local opts = {
    args = {'--headless','-u','NORC','--cmd', 'source lua/scratch/ts_util.lua'}, -- TODO: --clean, -u, -n, -i
    -- args = {'--headless','--cmd', 'source /Users/hk/.config/nvim/uppercase.lua'},
    stdio = { stdin, stdout, stderr },
    cwd = vim.fn.stdpath('config'),
  }
  handle, pid_or_err = uv.spawn("nvim", opts, function(code)
    uv.read_stop(stdout)
    uv.read_stop(stderr)
    safe_close(handle)
    safe_close(stdin)
    safe_close(stdout)
    safe_close(stderr)
    print(string.format('treesitter job done, spent time: %s ms at %s',(vim.loop.hrtime()-start)/1000000,vim.loop.hrtime()))
  end)
  uv.read_start(stderr, function(err, data)
    assert(not err, err)
  end)
  uv.read_start(stdout, vim.schedule_wrap(function(err, data)
    assert(not err,err)
    if data then
      data = sel.unpickle(data)
      self.data = data
      self.done = true
    end
  end))
  local send_input = sel.pickle(input) -- NOTE: input example: /Users/hk/.config/nvim/lua/scratch/a_input_t.lua
  uv.write(stdin, send_input)
  uv.write(stdin,'FINISHED')
  uv.shutdown(stdin, function()
    safe_close(stdin)
  end)
end
return M
