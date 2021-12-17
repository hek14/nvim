local log_path = vim.fn.expand("$HOME") .. "/.cache/nvim/neovim_debug.log"
local lprint = function(...)
  local arg = {...}
  local str = "שׁ "
  local lineinfo = ''

  local info = debug.getinfo(2, "Sl")
  lineinfo = info.short_src .. ":" .. info.currentline
  str = str .. lineinfo

  for i, v in ipairs(arg) do
    if type(v) == "table" then
      str = str .. " |" .. tostring(i) .. ": " .. vim.inspect(v) .. "\n"
    else
      str = str .. " |" .. tostring(i) .. ": " .. tostring(v)
    end
  end
  if #str > 2 then
    if log_path ~= nil and #log_path > 3 then
      local f = io.open(log_path, "a+")
      io.output(f)
      io.write(str .. "\n")
      io.close(f)
    else
      print(str .. "\n")
    end
  end
end

local add_timer = function(fn)
  local function timedFn()
    local wait = fn()
    if wait>0 then
      vim.defer_fn(timedFn, wait)
    end
  end
  timedFn()
end

local os_name = vim.loop.os_uname().sysname
local home = os.getenv("HOME")
local global = {
  is_mac = os_name == 'Darwin',
  is_linux = os_name == 'Linux',
  is_windows = os_name == 'Windows' or os_name == 'Windows_NT',
  home=home,
}

vim.cmd[[
  function! Cabbrev(key, value) abort
    execute printf('cabbrev <expr> %s (getcmdtype() == ":" && getcmdpos() <= %d) ? %s : %s',
          \ a:key, 1+len(a:key), Single_quote(a:value), Single_quote(a:key))
  endfunction

  function! Single_quote(str) abort
    return "'" . substitute(copy(a:str), "'", "''", 'g') . "'"
  endfunction
]]

return {lprint=lprint,timer=add_timer,global_env=global}
