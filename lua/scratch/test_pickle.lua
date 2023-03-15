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

  local wrapped_handle = function ()
    local last_data = ""
    local init = true
    local wrapped = function(err, raw_input)
      log('get back raw_input: ',type(raw_input),raw_input)
      if init then
        last_data = raw_input
        init = false
      else
        last_data = string.sub(last_data,1,#last_data-1) .. raw_input
      end
      if string.match(raw_input,'END$') then
        local data = decoding(last_data)
        log('return back: ',data)
        if data then
          log('keys number: ',#vim.tbl_keys(data))
          for k,v in pairs(data) do
            log('return equal: ',vim.deep_equal(v,M.t),vim.deep_equal(v,M.t2),#v,#M.t,#M.t2)
          end
        end
        last_data = ""
        init = true
      end
    end
    return wrapped
  end

  -- vim.loop.stream_set_blocking(stdin,true)
  for i = 1,20 do
    vim.loop.write(stdin,encoding(M.t2, vim.loop.hrtime()))
  end
  -- vim.loop.sleep(100)
  vim.loop.write(stdin,encoding(M.t2, vim.loop.hrtime()))
  -- vim.loop.sleep(50)
  -- vim.loop.write(stdin,encoding(M.t, vim.loop.hrtime()))
  -- vim.loop.sleep(10)
  -- vim.loop.write(stdin,encoding(M.t2, vim.loop.hrtime()))
  -- vim.loop.write(stdin,encoding(M.t, vim.loop.hrtime()))

  vim.loop.read_start(stdout, wrapped_handle())
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
  local wrapped_handle = function ()
    -- NOTE: delay: if the two interval is less than delay, it should be thought as a same stdin
    local last_data = ""

    local wrapped = function(id,raw_input,event)
      if raw_input and #raw_input == 1 and #raw_input[1] > 0 then
        raw_input = raw_input[1] -- the str itself
        last_data = last_data .. raw_input
        if string.match(raw_input,'END$') then
          local data = decoding(last_data)
          if data then
            for k,v in pairs(data) do
              log('equal: ',vim.deep_equal(v,M.t),vim.deep_equal(v,M.t2))
              if vim.deep_equal(v,M.t) then
                local to_return = encoding(M.t,k)
                log('ro return type: ',type(to_return))
                vim.fn.chansend(id,to_return)
              else
                local to_return = encoding(M.t2,k)
                log('ro return type: ',type(to_return))
                vim.fn.chansend(id,to_return)
              end
            end
          end
          last_data = ""
        end
      else
        log('no: ',raw_input)
      end
    end

    return wrapped
  end
  local handle = wrapped_handle()
  vim.fn.stdioopen({on_stdin = handle})
end

return M
