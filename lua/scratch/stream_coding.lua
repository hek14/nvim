local sel = require('scratch.serialize')
local log = require('core.utils').log
local fmt = string.format

local encoding = function(t,tick, as_str)
  -- input: table1
  -- return: "START_12345_${table1}#_12345_END"
  local content = sel.pickle(t)

  if as_str then
    -- method 1: a string: the receiver will get a table of string (typically split by '\n')
    -- but if the string is very long, maybe each item will not ended with '\n'
    return fmt('START_%d_$',tick) .. content .. fmt('#_%d_END',tick)
  else -- as table
    -- method 2: a table of string: the receiver will get the whole string
    content = vim.split(content,'\n')
    table.insert(content,1,fmt('START_%d_$',tick))
    table.insert(content,#content+1,fmt('#_%d_END',tick))
    return content
  end
end

local decoding = function (s)
  -- input: "START_12345_${table1}#_12345_ENDSTART_45678_${table2}#_45678_END"
  -- return: { '12345' = table1, '45678' = table2 }
  local check_begin = function(ss)
    return string.sub(ss,1,5) == 'START' 
  end

  if not check_begin(s) then log('error: start') log(s) return end

  local t = {}
  local start_dollar, end_dollar
  local start_tick,   end_tick
  local start_mark,   end_mark
  while true do
    if not check_begin(s) then log('error start middle') return end

    start_mark = string.find(s,'START')
    start_dollar = string.find(s,'%$')
    start_tick = string.sub(s, 7, start_dollar-2)

    end_mark = string.find( s, 'END')
    end_dollar =  string.find( s, '#')
    end_tick = string.sub(s,end_dollar+2, end_mark-2) 

    if start_tick~=end_tick then log('error start_tick~=end_tick') return end

    local tbl_str = string.sub(s,start_dollar+1,end_dollar-1)
    local tbl = sel.unpickle(tbl_str)
    t[start_tick] = tbl

    s = string.sub(s,end_mark+3)
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
    if string.match(last_data,'END$') then
      local ok, data = pcall(decoding,last_data)
      if not ok or data==nil then
        log('decoding err: ',data)
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
      if string.match(last_data,"END$") then
        local ok, data = pcall(decoding,last_data)
        if not ok or data==nil then
          log('decoding err: ',data)
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
