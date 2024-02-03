local my_tone = function(text)
  local to_check = {[[`]], [[']], [["]], [[“]], [[‘]]}
  local stk = {}
  local match = function(a, b)
    if(a==[[`]] and b==[[`]]) then
      return true;
    end
    if(a==[[']] and b==[[']]) then
      return true;
    end
    if(a==[["]] and b==[["]]) then
      return true;
    end
    if(a==[[“]] and b==[[“]]) then
      return true;
    end
    if(a==[[‘]] and b==[[‘]]) then
      return true;
    end
    return false
  end

  for i = 1, #text do
    local c = text:sub(i,i)
    -- print(string.format("%d %s", i, c))
    if vim.tbl_contains(to_check, c) then
      if(#stk>0 and match(stk[#stk], c)) then
        -- print("matched")
        stk = vim.list_slice(stk, 1, #stk-1)
      else
        -- print("not match")
        stk[#stk+1] = c
      end
    end
  end

  if #stk>0 then
    return false
  else
    return true
  end
end

local function read_file(filepath)
    local file = io.open(filepath, "r") -- Open the file for reading
    if not file then return nil, "Unable to open file" end
    local content = file:read("*a") -- Read the entire file content
    file:close()
    local lines = vim.split(content, "\n") -- Split content into lines
    return lines
end

local file = vim.fn.expand("~/Documents/Notes/Vault/剑指offer刷题笔记.md")
local lines, err = read_file(file)
if err then
  print(err)
  return
end

for i, line in ipairs(lines) do
  if(string.match(line, [[^ *```]])) then
    -- print(string.format("just block %s", line))
  else
    if not my_tone(line) then
      print(string.format("%s %d not ok: %s", file, i, line))
    end
  end
end
print(string.format("%s is ok", file))
