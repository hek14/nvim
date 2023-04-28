local M = {}
function M.once_map(lhs,callback,buf_map)
  lhs = lhs:gsub("<leader>"," ")
  lhs = lhs:gsub("<space>"," ")
  local bufnr = vim.api.nvim_get_current_buf()
  local cached
  local found
  local mapglobal = vim.api.nvim_get_keymap('n')
  local maplocal = vim.api.nvim_buf_get_keymap(bufnr,'n')
  for i, item in ipairs(mapglobal) do
    if lhs == item.lhs then
      cached = item
      found = 'global'
    end
  end
  if not found then
    for i, item in ipairs(maplocal) do
      if lhs == item.lhs then
        cached = item
        found = 'local'
      end
    end
  end

  vim.keymap.set('n',lhs,function()
    -- do your one time function stuff
    callback()
    if not found then
      vim.keymap.del('n',lhs,{buffer = buf_map and bufnr or nil})
    else
      if cached.rhs then
        vim.keymap.set('n',lhs, cached.rhs, {noremap=cached.noremap,nowait=cached.nowait,silent=cached.silent,buffer=found=='local'})
      else
        vim.keymap.set('n',lhs, '', {callback=cached.callback,noremap=cached.noremap,nowait=cached.nowait,silent=cached.silent,buffer=found=='local'})
      end
    end
  end,{noremap = true, nowait = true, buffer = buf_map})
end
return M
