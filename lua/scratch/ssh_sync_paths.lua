local f = string.format

local std_out = {}
local std_err = {}

local function dump_strings_to_file(filename, content)
  local file = io.open(filename, "w")
  if file then
    for _, str in ipairs(content) do
      file:write(str .. "\n")
    end
    file:close() -- Close the file
  else
    print("Failed to open file: " .. filename)
  end
end

local on_stdout = function(job_id, data, _)
  for e, item in ipairs(data) do
    table.insert(std_out, item)
  end
end

local on_stderr = function(job_id, data, _)
  for e, item in ipairs(data) do
    table.insert(std_err, item)
  end
end

local on_exit = function(job_id, err, _)
  local is_empty = function(e)
    return e == nil or #e == 0
  end
  local is_not_empty = function(e)
    return not is_empty(e)
  end
  std_out = vim.tbl_filter(is_not_empty, std_out)
  table.sort(std_out)
  dump_strings_to_file(string.gsub("~/server_files/qingdao/solved.path", "~", vim.env["HOME"]), std_out)
end

vim.fn.jobstart([[ssh qingdao 'cd ~/codes_med33/CHI2024; fd --no-ignore ".*"']], {
  on_stderr = on_stderr, on_stdout = on_stdout, on_exit = on_exit, stdout_bufferd = true
})
