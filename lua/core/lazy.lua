-- load builtin plugin before lazy.nvim, because lazy.nvim will totally change &rtp
vim.cmd[[packadd! cfilter]]
vim.cmd[[packadd! matchit]]

-- bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  local result = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.api.nvim_get_vvar "shell_error" ~= 0 then
    vim.api.nvim_err_writeln("Error install lazy.nvim:\n" .. "\nCheck your proxy:\n" .. result)
  end
end
vim.opt.runtimepath:prepend(lazypath)

require('lazy').setup("plugins", {
  defaults = { lazy = true },
})
