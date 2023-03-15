local log = require('core.utils').log
local fmt = string.format
local M = {}
local file_watchers = {}
local timer_id = 1

local new_watcher = function(path,cb_modified,cb_err)
  local stat = vim.loop.fs_stat(path)
  if not stat then
    return nil
  end

  local last_mtime = stat.mtime.nsec
  local last_func_ended = true
  local running = true
  local timer = vim.loop.new_timer()
  local cancel = function ()
    if not timer:is_closing() then
      running = false
      timer:stop()
      timer:close()
    end
  end
  timer:start(10,100,vim.schedule_wrap(function()
    if not last_func_ended then return end
    if not running then return end

    local start = vim.loop.hrtime()
    local stat = vim.loop.fs_stat(path)
    if not stat then
      cb_err(path)
      last_func_ended = true
      return
    end

    local now_mtime = stat.mtime.nsec
    if now_mtime ~= last_mtime then
      cb_modified(path,now_mtime)
      last_mtime = now_mtime
    end
    last_func_ended = true
  end))
  return timer,cancel
end

M.remove_watcher = function(path)
  if file_watchers[path] then 
    file_watchers[path].cancel()
    file_watchers[path].timer = nil
    file_watchers[path] = nil
    log('remove, current watchers: ', vim.tbl_keys(file_watchers))
  end
end

local default_cb_err = function (path)
  -- log('watch path failed: ',path)
end

M.add_watcher = function(path,cb_modified,cb_err)
  if file_watchers[path] then
    log('already have watcher')
    return
  end
  local timer,cancel = new_watcher(path,cb_modified,cb_err or default_cb_err)
  file_watchers[path] = {timer=timer,cancel=cancel,id=timer_id}
  log('add, current watchers: ')
  for k,v in pairs(file_watchers) do
    log(fmt('path: %s',k))
  end
end

M.timers = file_watchers

return M
