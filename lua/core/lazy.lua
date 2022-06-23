-- vim.tbl_contains to check whether an item is in a table
local lazy_timer = 50
local function LazyLoad() -- not necessary to use global function for nvim_create_autocmd
  local loader = require"packer".loader
  _G.PLoader = loader
  loader('nvim-cmp cmp-cmdline telescope.nvim') -- the vanilla 'require("nvim-cmp")' will not work here
  require("luasnip/loaders/from_vscode").load()
  vim.defer_fn(function ()
    -- require the plugin config, although the command PackerCompile will require this
    require("plugins")
  end,50)
  -- method 1 of loading a packer configed package: dominated by packer(event,ft,module,key,command, etc. all lazy but automatically)
  -- method 2 of loading a packer configed package: manually load the package using the packer.loader just like above
  -- using the packer's loader instead of vanilla require, the config part of each package powered by packer.nvim will still work
end
local group = vim.api.nvim_create_augroup("kk_LazyLoad",{clear=true})
vim.api.nvim_create_autocmd("User",{pattern="LazyLoad",callback=LazyLoad,group=group}) -- NOTE: autocmd User xxx, xxx is the pattern
vim.defer_fn(function() vim.cmd([[doautocmd User LazyLoad]]) end,lazy_timer)
-- the LazyLoad function will be called after custom/init.lua and plugin/packer_compiled.lua (you can add print to check this), check scratch/defer_fn.lua for more details
