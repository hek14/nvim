local uv = vim.loop

local function new_task(start_server)
  return {
    quenue = {},
    start_server = start_server,
  }
end

local function tbl_index(tbl, val)
  for i, v in ipairs(tbl) do
    if v == val then
      return i
    end
  end
end

local function async_search(task, startpath, patterns, checker)
  startpath = vim.fn.fnamemodify(startpath, ':h') or uv.cwd()

  local function search_pattern(dir, callback)
    if dir == uv.os_homedir() then
      return callback(nil)
    end

    uv.fs_scandir(dir, function(err, _)
      assert(not err)
      for _, pattern in ipairs(patterns) do
        local stat = uv.fs_stat(dir .. '/' .. pattern)
        if stat then
          return callback(dir)
        end
      end
      search_pattern(uv.fs_realpath(dir .. '/..'), callback)
    end)
  end

  local co
  co = coroutine.create(function()
    search_pattern(startpath, function(path)
      return coroutine.resume(co, path)
    end)

    local root = coroutine.yield()
    if root and checker(root) then
      task.start_server(root)
      return
    end

    local index = tbl_index(co)
    if not index or index + 1 > #task.quenue then
      return
    end

    while true do
      local next_co = task.quenue[#task.quenue + 1]
      coroutine.resume(next_co)
      index = index + 1
      if index > #task then
        return
      end
    end
  end)

  task.quenue[#task.quenue + 1] = co
  coroutine.resume(co)
  return co
end

local function async_find_git(task, startpath)
  return async_search(task, startpath, { '.git' })
end

return {
  new_task = new_task,
  async_search = async_search,
  async_find_git = async_find_git,
}
