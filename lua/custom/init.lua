-- This is where your custom modules and plugins go.
-- See the wiki for a guide on how to extend NvChad

_G.lprint = require('custom.utils').lprint
local hooks = require "core.hooks"

-- NOTE: To use this, make a copy with `cp example_init.lua init.lua`

--------------------------------------------------------------------

-- To modify packaged plugin configs, use the overrides functionality
-- if the override does not exist in the plugin config, make or request a PR,
-- or you can override the whole plugin config with 'chadrc' -> M.plugins.default_plugin_config_replace{}
-- this will run your config instead of the NvChad config for the given plugin

-- hooks.override("lsp", "publish_diagnostics", function(current)
--   current.virtual_text = false;
--   return current;
-- end)

-- To add new mappings, use the "setup_mappings" hook,
-- you can set one or many mappings
-- example below:

hooks.add("setup_mappings", function(map)
  map("n", "<leader>cd", "<cmd>:cd %:p:h<cr>", {silent=false}) -- example to delete the buffer

  map("n", "n", "j",   {silent=true,noremap=true}) -- example to delete the buffer
  map("x", "n", "j",   {silent=true,noremap=true}) -- example to delete the buffer
  map("n", "N", "J",   {silent=true,noremap=true}) -- example to delete the buffer
  map("x", "N", "J",   {silent=true,noremap=true}) -- example to delete the buffer
  map("n", "gn", "gj", {silent=false,noremap=true}) -- example to delete the buffer

  map("n", "e", "k",   {silent=true,noremap=true}) -- example to delete the buffer
  map("x", "e", "k",   {silent=true,noremap=true}) -- example to delete the buffer
  map("n", "E", "K",   {silent=true,noremap=false}) -- example to delete the buffer
  map("x", "E", "K",   {silent=true,noremap=false}) -- example to delete the buffer
  map("n", "ge", "gk", {silent=false,noremap=true}) -- example to delete the buffer

  map("n", "i",  "l",  {silent=false,noremap=true}) -- example to delete the buffer
  map("x", "i",  "l",  {silent=false,noremap=true}) -- example to delete the buffer
  map("o", "i",  "l",  {silent=false,noremap=true}) -- example to delete the buffer

  map("n", "k",  "n",  {silent=false,noremap=true}) -- example to delete the buffer
  map("x", "k",  "n",  {silent=false,noremap=true}) -- example to delete the buffer
  map("o", "k",  "n",  {silent=false,noremap=true}) -- example to delete the buffer
  map("n", "K",  "N",  {silent=false,noremap=true}) -- example to delete the buffer
  map("x", "K",  "N",  {silent=false,noremap=true}) -- example to delete the buffer
  map("o", "K",  "N",  {silent=false,noremap=true}) -- example to delete the buffer

  map("n", "u",  "i",  {silent=false,noremap=true}) -- example to delete the buffer
  map("x", "u",  "i",  {silent=false,noremap=true}) -- example to delete the buffer
  map("o", "u",  "i",  {silent=false,noremap=true}) -- example to delete the buffer
  map("n", "U",  "I",  {silent=false,noremap=true}) -- example to delete the buffer
  map("x", "U",  "I",  {silent=false,noremap=true}) -- example to delete the buffer
  map("o", "U",  "I",  {silent=false,noremap=true}) -- example to delete the buffer

  map("n", "l",  "u",  {silent=false,noremap=true}) -- example to delete the buffer
  map("x", "l",  "u",  {silent=false,noremap=true}) -- example to delete the buffer
  map("o", "l",  "u",  {silent=false,noremap=true}) -- example to delete the buffer
  map("n", "l",  "u",  {silent=false,noremap=true}) -- example to delete the buffer
  map("x", "l",  "u",  {silent=false,noremap=true}) -- example to delete the buffer
  map("o", "l",  "u",  {silent=false,noremap=true}) -- example to delete the buffer

  map({"n","x"}, "<C-w>n", "<C-w>j", {silent=false,noremap=true})
  map({"n","x"}, "<C-w>e", "<C-w>k", {silent=false,noremap=true})
  map({"n","x"}, "<C-w>i", "<C-w>l", {silent=false,noremap=true})

  map("x", ">", ">gv", {silent=false,noremap=true})
  map("x", "<", "<gv", {silent=false,noremap=true})
  map("n", "<leader>rr", "<cmd>lua require('telescope.builtin').resume()<CR>")
  
  map("t","<C-w>n", "<C-\\><C-n><C-w>j")
  map("t","<C-w>e", "<C-\\><C-n><C-w>k")
  map("t","<C-w>i", "<C-\\><C-n><C-w>l")
  vim.cmd([[
    call Cabbrev('pi', 'PackerInstall')
    call Cabbrev('pud', 'PackerUpdate')
    call Cabbrev('pc', 'PackerCompile')
    call Cabbrev('ps', 'PackerSync')
    call Cabbrev('so', 'lua Source_curr_file()<CR>')
    call Cabbrev('li', 'let i =1 \|')
  ]])
end)

function Source_curr_file ()
  if vim.bo.ft == "lua" then
    vim.cmd[[luafile %]]
  elseif vim.bo.ft == "vim" then
    vim.cmd[[so %]]
  end
end

function _G.put(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, '\n'))
  return ...
end

vim.cmd [[
  function! Inc(...)
    let result = g:i
    let g:i += a:0 > 0 ? a:1 : 1
    return result
  endfunction
]]

-- To add new plugins, use the "install_plugin" hook,
-- NOTE: we heavily suggest using Packer's lazy loading (with the 'event' field)
-- see: https://github.com/wbthomason/packer.nvim
-- examples below:

hooks.add("install_plugins", function(use)
  print('in the hook of install_plugins')
  use {
    "williamboman/nvim-lsp-installer",
  }
  use {
    'RishabhRD/nvim-lsputils',
    disable = true,
    requires = 'RishabhRD/popfix',
    after = "nvim-lspconfig",
    config = require"custom.plugins.lsputils".setup,
  }
  use {
    "folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require("trouble").setup {}
    end
  }
  use {
    "ahmedkhalf/project.nvim",
    config = require"custom.plugins.project".setup
  }
  use {
    "tmhedberg/SimpylFold",
    config = function ()
      vim.g.SimpylFold_docstring_preview = 1
    end
  }
  use { "nathom/filetype.nvim" }
  -- dap stuff
  use { 
    'mfussenegger/nvim-dap',
    disable = true,
    requires = {
      "nvim-telescope/telescope-dap.nvim",
      "theHamsta/nvim-dap-virtual-text",
      "mfussenegger/nvim-dap-python",
    },
    event = 'VimEnter',
    config = function ()
      require('custom.plugins.dap')
    end
  }
  use {
    'sakhnik/nvim-gdb',
  }
  use {
    "Pocco81/TrueZen.nvim",
    cmd = {
      "TZAtaraxis",
      "TZMinimalist",
      "TZFocus",
    },
    setup = function()
      require'core.utils'.map("n","gq","<cmd>TZFocus<CR>")
      require'core.utils'.map("i","<C-q>","<cmd>TZFocus<CR>")
    end,
  }
  use {
    "blackCauldron7/surround.nvim",
    event = "BufEnter",
    config = function ()
      require"surround".setup {mappings_style = "surround"}
    end
  }
  use {
    "ggandor/lightspeed.nvim",
    event = "VimEnter",
    config = function ()
      require('lightspeed').setup({})
    end
  }
  use {
    "hrsh7th/cmp-cmdline",
    after = "cmp-buffer",
    config = function ()
      local cmp = require("cmp")
      cmp.setup.cmdline('/', {
        sources = {
          { name = 'buffer' }
        }
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(':', {
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })
    end
  }
  -- enhance grep and quickfix list
  -- 1. populate the quickfix
  use {
    "mhinz/vim-grepper",
    config = function()
      vim.g.grepper = {tools = {'rg', 'grep'}, searchreg = 1, next_tool = '<leader>gw' }
      vim.cmd([[
        nnoremap <leader>gw :Grepper<cr>
        nmap <leader>gs  <plug>(GrepperOperator)
        xmap <leader>gs  <plug>(GrepperOperator)
      ]])
    end
  }
  -- 2. setup better qf buffer
  use {'kevinhwang91/nvim-bqf'}
end
)

vim.g.matchup_surround_enabled = 1
vim.g.matchup_text_obj_enabled = 1

local lazy_timer = 50
function LazyLoad()
  local loader = require"packer".loader
  _G.PLoader = loader
  print("I am lazy")
  loader('nvim-cmp cmp-cmdline vim-matchup gitsigns.nvim telescope.nvim nvim-lspconfig')

end
vim.cmd([[autocmd User LoadLazyPlugin lua LazyLoad()]])
vim.defer_fn(function()
  vim.cmd([[doautocmd User LoadLazyPlugin]])
end, lazy_timer)

function Buf_attach()
  vim.defer_fn(function ()
    local cmd_str = [[xunmap <buffer> ih]] -- NOTES: xunmap ih will not work in this case!!! buffer local keymaps should unmap using <buffer> too
    lprint(cmd_str)
    local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok

    local cmd_str = [[ounmap <buffer> ih]]
    lprint(cmd_str)
    local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok

    local cmd_str = [[xunmap i%]]
    lprint(cmd_str)
    local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok

    local cmd_str = [[ounmap i%]]
    lprint(cmd_str)
    local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok
  end,250) -- 250 should be enough for buffer local plugins to load
  -- require("custom.utils").timer(function ()
    --   local bufnr = vim.api.nvim_get_current_buf()
    --   if vim.api.nvim_buf_is_valid(bufnr) then
    --     local ok,timer = pcall(vim.api.nvim_buf_get_var,bufnr,'timer')
    --     if not ok then
    --       timer = 0
    --     else
    --       timer = vim.api.nvim_buf_get_var(bufnr,'timer')
    --     end
    --     local ok_all = true
    --
    --     local cmd_str = [[xunmap <buffer> ih]] -- NOTES: xunmap ih will not work in this case!!! buffer local keymaps should unmap using <buffer> too
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     local cmd_str = [[ounmap <buffer> ih]]
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     local cmd_str = [[xunmap i%]]
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     local cmd_str = [[ounmap i%]]
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     -- local cmd_str = [[lua vim.api.nvim_buf_del_keymap(]] .. tostring(bufnr) .. [[ , 'x' , 'i%')]]
    --     -- lprint(cmd_str)
    --     -- local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     -- ok_all = ok_all and ok
    --
    --     if packer_plugins['vim-matchup'].loaded then
    --       vim.api.nvim_buf_set_keymap(bufnr,'x','u%','<Plug>(matchup-i%)',{silent=true, noremap=false})
    --     end
    --     if packer_plugins['gitsigns.nvim'].loaded then
    --       vim.api.nvim_buf_set_keymap(bufnr,'x','uh',':<C-U>Gitsigns select_hunk<CR>',{silent=true, noremap=false})
    --       vim.api.nvim_buf_set_keymap(bufnr,'o','uh',':<C-U>Gitsigns select_hunk<CR>',{silent=true, noremap=false})
    --     end
    --     if ok then
    --       return -1
    --     else
    --       if timer<300 then
    --         vim.api.nvim_buf_set_var(bufnr,"timer",timer+10)
    --         return 10
    --       else
    --         return -1
    --       end
    --     end
    --   end
    -- end)
  end
vim.cmd([[autocmd BufEnter * lua Buf_attach()]])
-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
vim.cmd [[
  autocmd VimEnter lua require('custom.plugins.cmp')
]]

vim.cmd [[
  au BufRead * set foldlevel=99
 autocmd BufWinEnter,WinEnter term://* startinsert
 autocmd BufLeave term://* stopinsert
 autocmd BufRead *.py nmap <buffer> gm /^if.*__main__<cr> :noh <cr> 0

 autocmd BufWinEnter * if &buftype =~? '\(terminal\|prompt\|nofile\)' | silent! nnoremap <buffer> <silent> <Esc> :bd<CR>| endif
  " Return to last edit position when opening files (You want this!)
  autocmd BufReadPost *
       \ if line("'\"") > 0 && line("'\"") <= line("$") |
       \   exe "normal! g`\"" |
       \ endif
]]
-- autocmd BufWinEnter,WinEnter * if &buftype =~? '\(terminal\|prompt\)' | silent! normal! i | endif
-- vim.api.nvim_del_keymap("o","i%")
