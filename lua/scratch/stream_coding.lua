-- NOTE: you can refer to the `chunks` process in easyformat.nvim format.lua, concat all of the chunks with '' and then split by '\n'
-- in on_stdout:
--   uv.read_start(stdout, function(err, data)
--     -- data is string
--     assert(not err, err)
--     if data then
--       chunks[#chunks + 1] = data
--     end
--   end)
-- in on_exit: 
--   chunks = vim.split(table.concat(chunks, ''), '\n')
--   if #chunks[#chunks] == 0 then
--     table.remove(chunks, #chunks)
--   end


local sel = require('scratch.serialize')
local log = require('core.utils').log
local fmt = string.format

local header = 'STREAM_CODE_START'
local ender = 'TRATS_EDOC_MAERTS'

local encoding = function(t,tick)
  local content = sel.pickle(t)
  -- method 2: a table of string: the receiver will get the whole string
  content = vim.split(content,'\n')
  table.insert(content,1,fmt('%s%d', header, tick))
  table.insert(content,#content+1,fmt('%d%s', tick, ender))
  return content
end

local decoding = function (s)
  local t = {}
  while true do
    local left_start, left_end = string.find(s, fmt([[%s[0-9]+]],header))
    local right_start, right_end = string.find(s, fmt([[[0-9]+%s]],ender)) -- only the first match!

    local start_tick = string.sub(s,left_start+#header,left_end)
    local end_tick = string.sub(s,right_start,right_end-#ender)

    if start_tick~=end_tick then
      log('start_tick~=end_tick',start_tick,end_tick)
      log('s:',s)
      return
    end

    local tbl_str = string.sub(s, left_end+1,right_start-1)
    local ok,tbl = pcall(sel.unpickle,tbl_str)
    if not ok then
      assert(ok, 'unpickle error')
    end
    t[start_tick] = tbl

    s = string.sub(s,right_end+1)
    if #s==0 then
      break
    end
  end
  return t
end

local wrap_for_on_stdout = function(cb)
  -- NOTE: for: receiving from chansend, the raw_input is string (separated by '\n')
  local last_data = ""
  local wrapped = function(err, raw_input)
    if err then
      log('stdout receive err: ',err)
      return
    end
    if not raw_input then return end
    raw_input = raw_input:gsub('\n','')
    -- log("stdou receive raw_input: ",raw_input)
    if not raw_input or #raw_input==0 or err then 
      log('err:',err,'raw_input:',raw_input) 
      return 
    end
    -- NOTE: concat the end with the start(remove the \n)
    last_data = last_data .. raw_input
    if string.match(last_data,fmt([[%s$]],ender)) then
      local ok, data = pcall(decoding,last_data)
      if not ok or data==nil then
        log('stdout decoding err: ',data)
        log('current data: ',last_data)
        assert(ok, 'decoding error')
        return
      end
      cb(data,err,raw_input)
      last_data = ""
    end
  end
  return wrapped
end

local wrap_for_stdin_handle = function(cb)
  -- NOTE: for: receiving from vim.loop.write(stdin) 
  local last_data = ""
  local valid_raw_input = function (raw_input)
    local ret = (raw_input and #raw_input == 1 and #raw_input[1] > 0)
    if not ret then
      log('invalid raw_input: ',raw_input)
    end
    return ret
  end

  local wrapped = function(id,raw_input,event)
    if valid_raw_input(raw_input) then
      raw_input = raw_input[1] -- the str itself
      last_data = last_data .. raw_input
      if string.match(last_data,fmt([[%s$]],ender)) then
        local ok, data = pcall(decoding,last_data)
        if not ok or data==nil then
          log('stdin decoding err: ',data)
          log('current data: ',last_data)
          vim.fn.chansend(vim.v.stderr,"backend process error!")
          return
        end
        cb(data,id,raw_input,event)
        last_data = ""
      end
    end
  end
  return wrapped
end

return {
  encoding = encoding,
  decoding = decoding,
  wrap_for_stdin_handle = wrap_for_stdin_handle,
  wrap_for_on_stdout = wrap_for_on_stdout,
}
