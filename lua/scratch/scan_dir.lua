--- This file is used to scan a directory and find the empty files
-- in zsh, we use [[ while read file; do result=$(cat ${~file} | awk 'BEGIN{sum=0}; {val=0; if ($0 !~ "^ *$"){val=val+1};sum=sum+val}; END{if (sum == 0) print("Yes")}'); if [ "$result" = 'Yes' ]; then echo $file; fi;done <<(fd '\.md') ]]
---
local files = {}
local function read_dir(dir)
  local fs, err = vim.loop.fs_scandir(vim.fn.expand(dir))
  while true do
    local name, fs_type, e = vim.loop.fs_scandir_next(fs)
    if e then
      print("error: ",e)
    end
    if not name then
      break
    end
    if(fs_type == 'directory') then
      read_dir(dir .. "/" .. name)
    else
      files[#files+1] = dir .. "/" .. name
    end
  end
end

local function read_file(filepath)
  filepath = vim.fn.expand(filepath)
  local file = io.open(filepath, "r") -- Open the file for reading
  if not file then return nil, "Unable to open file" end
  local content = file:read("*a") -- Read the entire file content
  file:close()
  local lines = vim.split(content, "\n") -- Split content into lines
  return lines
end

local dir_to_scan = vim.fn.input("dir_to_scan: ", vim.loop.cwd())
if(not dir_to_scan) then
  print("no dir input")
  return
end
read_dir(dir_to_scan)
for i, file in ipairs(files) do
  if(not string.match(file, [[%.md$]])) then
    goto continue
  end
  local lines = read_file(file)
  if not lines then
    print("read error: ", file)
    goto continue
  end
  local empty = 0
  for i, line in ipairs(lines) do
    if(string.match(line, "^ *$")) then
      empty = empty + 1
    end
  end
  if(empty == #lines) then
    print("total empty: " .. file)
  end
  ::continue::
end
