vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    local is_mac = vim.loop.os_uname().sysname=="Darwin"
    if is_mac then
      print('please use startuptime to profile')
      return
    else
      local pid = vim.loop.os_getpid()
      local ctime = vim.loop.fs_stat("/proc/" .. pid).ctime
      local start = ctime.sec + ctime.nsec / 1e9
      local tod = { vim.loop.gettimeofday() }
      local now = tod[1] + tod[2] / 1e6
      local startuptime = (now - start) * 1000
      vim.notify("startup: " .. startuptime .. "ms")
    end
  end,
})

local modules = {
   "core.utils",
   "core.options",
   "core.lazy",
   "core.autocmds",
   "core.mappings",
}

for _, module in ipairs(modules) do
   local ok, err = pcall(require, module)
   if not ok then
      error("Error loading " .. module .. "\n\n" .. err)
   end
end
