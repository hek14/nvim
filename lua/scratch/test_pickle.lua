local print = vim.pretty_print
local fmt = string.format
local M = {}
M.t = require("scratch.large_input_t")
M.t2 = require('scratch.two_input_t')
local log = require('core.utils').log

local function safe_close(handle)
  if not vim.loop.is_closing(handle) then
    vim.loop.close(handle)
  end
end

local encoding = require('scratch.stream_coding').encoding
local decoding = require('scratch.stream_coding').decoding

function M.send()
  local stdin = vim.loop.new_pipe(false)
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local handle
  local opts = {
    args = {'--headless','-u','NORC','-i','NONE','-n','--cmd', 'lua require("scratch.test_pickle").receive()'},
    stdio = { stdin, stdout, stderr },
    cwd = vim.fn.stdpath('config'),
  }
  local on_exit = vim.schedule_wrap(function(code)
    vim.loop.read_stop(stdout)
    vim.loop.read_stop(stderr)
    safe_close(handle)
    safe_close(stdin)
    safe_close(stdout)
    safe_close(stderr)
  end)
  handle = vim.loop.spawn("nvim", opts, on_exit)

  vim.loop.read_start(stdout, vim.schedule_wrap(function(err, data)
    assert(not err,err)
    if data then
      data = decoding(data)
      print('data: ',data)
    end
  end))
  -- vim.loop.stream_set_blocking(stdin,true)
  for i = 1,50 do
    vim.loop.write(stdin,encoding(M.t2, vim.loop.hrtime()))
    vim.loop.write(stdin,encoding(M.t2, vim.loop.hrtime()))
    vim.loop.write(stdin,encoding(M.t2, vim.loop.hrtime()))
  end
  -- vim.loop.write(stdin,encoding(M.t2, vim.loop.hrtime()))
  -- vim.loop.sleep(50)
  -- vim.loop.write(stdin,encoding(M.t, vim.loop.hrtime()))
  -- vim.loop.sleep(50)
  -- vim.loop.write(stdin,encoding(M.t2, vim.loop.hrtime()))
end


function M.receive()

  local handle = function(id,raw_input,event)
    if raw_input and #raw_input > 0 and type(raw_input[1])=='string' and #raw_input[1]>0 then
      local data = decoding(raw_input[1])
      -- log('data: ',data)
      if data then
        for k,v in pairs(data) do
          log('equal: ',vim.deep_equal(v,M.t),vim.deep_equal(v,M.t2))
          if vim.deep_equal(v,M.t) then
            local to_return = encoding({'is t'},k)
            vim.fn.chansend(id,to_return)
          else
            local to_return = encoding({'is t2'},k)
            vim.fn.chansend(id,to_return)
          end
        end
      end
    end
  end
  vim.fn.stdioopen({on_stdin = handle})
end

return M
