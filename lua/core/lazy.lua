-- load builtin plugin before lazy.nvim, because lazy.nvim will totally change &rtp
vim.cmd[[packadd cfilter]]
vim.cmd[[packadd matchit]]

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

-- disable some builtin vim plugins
local disabled_built_ins = {
  "2html_plugin",
  "getscript",
  "getscriptPlugin",
  "gzip",
  "logipat",
  "netrw",
  "netrwPlugin",
  "netrwSettings",
  "netrwFileHandlers",
  "tar",
  "tarPlugin",
  "rrhelper",
  "spellfile_plugin",
  "vimball",
  "vimballPlugin",
  "zip",
  "zipPlugin",
  "matchparen",
}

-- NOTE: no need to manually do the following:
-- for _, plugin in pairs(disabled_built_ins) do
--    g["loaded_" .. plugin] = 1
-- end

require('lazy').setup("plugins", {
  defaults = { lazy = true },
  performance = {
    rtp = {
       reset = false,
       disabled_plugins = disabled_built_ins
    }
  },
  ui = {
    custom_keys = {
      -- open lazygit log
      [",l"] = function(plugin)
        require("lazy.util").float_term({ "lazygit", "log" }, {
          cwd = plugin.dir,
        })
      end,
      -- open a terminal for the plugin dir
      [",t"] = function(plugin)
        require("lazy.util").float_term(nil, {
          cwd = plugin.dir,
        })
      end,
    },
  }
})

vim.api.nvim_create_user_command('Lazysync',function ()
  vim.fn.system("~/.config/nvim/bin/clear_lazy")
  vim.cmd [[ Lazy sync ]]
end,{})

vim.keymap.set('n','<leader>ll',"<Cmd>Lazy<CR>",{ noremap = true,silent = true })
