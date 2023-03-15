local sel = require('scratch.serialize')
local log = require('core.utils').log
local fmt = string.format

local encoding = function(t,tick)
  -- input: table1
  -- return: "START_12345_${table1}#_12345_END"
  local content = sel.pickle(t)



  -- method 1: a string
  -- content = fmt('START_%d_$',tick) .. content .. fmt('#_%d_END',tick)


  -- method 2: a table of string
  content = vim.split(content,'\n')
  table.insert(content,1,fmt('START_%d_$',tick))
  table.insert(content,#content+1,fmt('#_%d_END',tick))


  return content
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

return {
  encoding = encoding,
  decoding = decoding
}
