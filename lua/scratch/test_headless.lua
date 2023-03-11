local uv = vim.loop
local sel = require('scratch.serialize')
local function safe_close(handle)
  if not uv.is_closing(handle) then
    uv.close(handle)
  end
end
local start = vim.loop.hrtime()
local function exe()
  local stdin = uv.new_pipe(false)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local handle,pid_or_err
  local opts = {
    args = {'--headless','--cmd', 'source /Users/hk/.config/nvim/lua/scratch/ts_util.lua'}, -- TODO: norc, --clean, -u, -n, -i
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
    print(string.format('spent time: %s ms',(vim.loop.hrtime()-start)/1000000))
  end)
  uv.read_start(stderr, function(err, data)
    assert(not err, err)
  end)
  uv.read_start(stdout, function(err, data)
    assert(not err,err)
    if data then
      data = sel.unpickle(data)
      print('receive data: ',vim.inspect(data))
      print('spent: ',(vim.loop.hrtime()-start)/1e6)
    end
  end)
  local test = {
    {
      file = '/Users/hk/.config/nvim/init.lua',
      filetick = 0,
      filetype = 'lua',
      position = {8,7},
    },
    {
      file = '/Users/hk/.config/nvim/test.lua',
      filetick = 0,
      filetype = 'lua',
      position = {6,16},
    },
    {
      file = '/Users/hk/.config/nvim/init.lua',
      filetick = 0,
      filetype = 'lua',
      position = {5,11},
    },
    {
      file = '/Users/hk/.config/nvim/lua/contrib/pig.lua',
      filetick = 0,
      filetype = 'lua',
      position = {162,32},
    },
    {
      file = '/Users/hk/.config/nvim/test.lua',
      filetick = 0,
      filetype = 'lua',
      position = {0,15},
    },
    {
      file = '/Users/hk/.config/nvim/test.lua',
      filetick = 0,
      filetype = 'lua',
      position = {1,17},
    },
    {
      file = '/Users/hk/.config/nvim/test.lua',
      filetick = 0,
      filetype = 'lua',
      position = {2,19},
    },
  }
  local send_input = sel.pickle(test)
  uv.write(stdin, send_input)
  uv.write(stdin, 'FINISHED')
end
require('core.utils').clear_log()
exe()
