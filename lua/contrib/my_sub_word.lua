local M = {}
local find_the_last_underline_before_loc = function(str,before_loc)
  local start = string.find(str,'_')
  if start == nil or start >= before_loc then 
    return 0
  else
    local res = nil
    while start and start < before_loc do
      res = start
      start = string.find(str,'_',start+1)
    end
    return res
  end
end

M.get_sub_word = function ()
  local word = vim.fn.expand('<cword>')
  local loc = vim.api.nvim_win_get_cursor(0)
  local col = loc[2]
  local line= vim.api.nvim_get_current_line()
  if string.sub(line,col+1,col+1)=='_' then
    return word
  end
  if #string.match(string.sub(line,col+1,col+1),'[^ ,.()]*')==0 then
    return nil
  end
  local m_start,m_end = string.find(line,word,0)
  while m_start do
    if m_start <= col + 1 and col + 1 <= m_end then
      break
    else
      m_start,m_end = string.find(line,word,m_start+1)
    end
  end
  col = col + 1 - m_start + 1
  m_start = 1
  m_end = #word
  local left = find_the_last_underline_before_loc(word,col) + 1
  local right = #word - find_the_last_underline_before_loc(string.reverse(word),#word-col+1)
  return string.sub(word,left,right)
end

return M
