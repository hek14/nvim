-- wrap with tick!!!!
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
      print('data: ', type(data), data)
    end
  end))
  -- vim.loop.stream_set_blocking(stdin,true)
  -- for i = 1,50 do
  --   vim.loop.write(stdin,encoding(M.t2, vim.loop.hrtime()))
  -- end
  vim.loop.write(stdin,encoding(M.t2, vim.loop.hrtime()))
  vim.loop.write(stdin,encoding(M.t, vim.loop.hrtime()))
  vim.loop.write(stdin,encoding(M.t2, vim.loop.hrtime()))
  vim.loop.write(stdin,encoding(M.t, vim.loop.hrtime()))
  vim.loop.write(stdin,'FINISH')
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

function M.receive()
  local wrapped_handle = function (delay)
    -- NOTE: delay: if the two interval is less than delay, it should be thought as a same stdin
    local last_time = 0
    local init = true
    local last_data = {}
    delay = delay or 10

    local ended = function(current)
      if type(current) == 'string' then
        if string.match(current,'FINISH$') then
          return true
        else
          return false
        end
      end
      if type(current) == 'table' then
        if string.match(current[#current],'FINISH$') then
          return true
        else
          return false
        end
      end
    end

    local wrapped = function(id,raw_input,event)
      local now = vim.loop.hrtime()
      log('interval: ',(now - last_time)/1e6)
      log('raw_input: ',raw_input)
      if init then
        last_data = raw_input
        init = false
      end

      if (now - last_time)/1e6 < delay then -- less than 10ms
        local ok, last_data = pcall(concat_tbl,last_data,raw_input)
        if not ok then
          log('err: ',last_data)
        end
      end
      last_time = now

      if ended(last_data) then
        local final_item = last_data[#last_data]
        last_data[#last_data] = string.sub(final_item, 1, #final_item - 6)
        log('ended!!!')
        local data = decoding(last_data)
        log('data: ',data)
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

    return wrapped
  end
  local handle = wrapped_handle(10)
  vim.fn.stdioopen({on_stdin = handle})
end

return M
