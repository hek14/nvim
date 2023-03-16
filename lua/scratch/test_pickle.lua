-- wrap with tick!!!!
local print = vim.pretty_print
local fmt = string.format
local M = {}
M.t = require("scratch.large_input_t")
M.t2 = require('scratch.two_input_t')
local log = require('core.utils').log
local coding_util = require("scratch.stream_coding")

local function safe_close(handle)
  if not vim.loop.is_closing(handle) then
    vim.loop.close(handle)
  end
end

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

  local cnt = 0
  local cb = function (data)
    for k,v in pairs(data) do
      cnt = cnt + 1
      log(fmt('current tick: %s, cnt: %s',k,cnt))
      if vim.deep_equal(v,M.t) then
        log('sender get t back')
      elseif vim.deep_equal(v,M.t2) then
        log('sender get t2 back')
      else
        log('error: ',v)
      end
    end
  end
  -- vim.loop.stream_set_blocking(stdin,true)
  for i = 1,20 do
    if i % 2 == 0 then
      vim.loop.write(stdin,coding_util.encoding(M.t2, vim.loop.hrtime()))
    else
      vim.loop.write(stdin,coding_util.encoding(M.t, vim.loop.hrtime()))
    end
  end
  vim.loop.sleep(50)
  vim.loop.write(stdin,coding_util.encoding(M.t2, vim.loop.hrtime()))
  -- vim.loop.sleep(50)
  -- vim.loop.write(stdin,encoding(M.t, vim.loop.hrtime()))
  -- vim.loop.sleep(10)
  -- vim.loop.write(stdin,encoding(M.t2, vim.loop.hrtime()))
  -- vim.loop.write(stdin,encoding(M.t, vim.loop.hrtime()))
  vim.loop.read_start(stdout, coding_util.wrap_for_on_stdout(cb))
end


local concat_tbl = function(t1,t2)
  local last_t1 = t1[#t1]
  local last_t1_last_char = string.sub(last_t1,#last_t1)
  if last_t1_last_char ~= ',' and last_t1_last_char ~= '{' and last_t1_last_char ~= '}' then
    t1[#t1] = t1[#t1] .. t2[1]
    for i,d in ipairs(t2) do  
      if i > 1 then
        t1[#t1+1] = d
      end
    end
  else
    for i,d in ipairs(t2) do  
      t1[#t1+1] = d
    end
  end
  return t1
end

local ended = function(current)
  local last = current[#current]
  if string.match(last,'END%$') then
  return true
else
  return false
end
end


function M.receive()
  local cb = function(data,id)
    for k,v in pairs(data) do
      log('headless handle: ',vim.deep_equal(v,M.t),vim.deep_equal(v,M.t2))
      if vim.deep_equal(v,M.t) then
        local to_return = coding_util.encoding(M.t,k, true)
        log('headless return t',type(to_return))
        -- vim.fn.chansend(id,to_return)
        vim.api.nvim_chan_send(id,to_return)
      elseif vim.deep_equal(v,M.t2) then
        local to_return = coding_util.encoding(M.t2,k, true)
        log('headless return t2',type(to_return))
        -- vim.fn.chansend(id,to_return)
        vim.api.nvim_chan_send(id,to_return)
      else
        log('err stdin: ',v)
      end
    end
  end
  vim.fn.stdioopen({on_stdin = coding_util.wrap_for_stdin_handle(cb)})
end

return M
