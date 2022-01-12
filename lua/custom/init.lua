local map = require('core.utils').map
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
map("n","<Up>",    "5<C-w>+")
map("n","<Down>",  "5<C-w>-")
map("n","<left>",  "5<C-w><")
map("n","<right>", "5<C-w>>")
map("n", "<Esc>", ":lua Closing_float_window()<CR>:noh<CR>")
vim.cmd([[
  call Cabbrev('pi', 'PackerInstall')
  call Cabbrev('pud', 'PackerUpdate')
  call Cabbrev('pc', 'PackerCompile')
  call Cabbrev('ps', 'PackerSync')
  call Cabbrev('so', 'lua Source_curr_file()<CR>')
  call Cabbrev('li', 'let i =1 \|')
  call Cabbrev('py', 'PYTHON')
  call Cabbrev('lg', 'Lazygit')
  call Cabbrev('ft', 'FloatermNew')
]])

function Closing_float_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do 
    local config = vim.api.nvim_win_get_config(win) 
    if config.relative ~= "" then 
      vim.api.nvim_win_close(win, false) 
      print('Closing window', win) 
    end 
  end
end

function Source_curr_file ()
  if vim.bo.ft == "lua" then
    vim.cmd[[luafile %]]
  elseif vim.bo.ft == "vim" then
    vim.cmd[[so %]]
  end
end

_G.lprint = require('custom.utils').lprint
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

local customPlugins = require "core.customPlugins"
customPlugins.add(function(use)
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
    disable = false,
    after = "telescope.nvim",
    requires = {
      "nvim-telescope/telescope-dap.nvim",
      "theHamsta/nvim-dap-virtual-text",
      "mfussenegger/nvim-dap-python",
      "rcarriga/nvim-dap-ui"
    },
    config = function ()
      require('custom.plugins.dap')
    end
  }
  use {
    'sakhnik/nvim-gdb',
    setup = function ()
      vim.g.nvimgdb_disable_start_keymaps = true
    end,
    config = function ()
      vim.cmd([[
        nnoremap <expr> <Leader>dd ":GdbStartPDB python -m pdb " . expand('%')
      ]])
      vim.cmd([[
        command! GdbExit lua NvimGdb.i():send('exit')
        nnoremap <Leader>ds :GdbExit<CR>
      ]])
    end
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
  use {'kevinhwang91/nvim-bqf', ft = 'qf'}

  use {
    "WhoIsSethDaniel/toggle-lsp-diagnostics.nvim",
    after = 'nvim-lspconfig',
    config = function ()
      vim.cmd [[command! -nargs=0 ToggleDiagVirtual lua require'toggle_lsp_diagnostics'.toggle_virtual_text()]]
    end
  }
  use {
    'SmiteshP/nvim-gps',
    -- this plugin shows the code context in the statusline: check ~/.config/nvim/lua/plugins/configs/statusline.lua
    after = {"nvim-treesitter","nvim-web-devicons"},
    config = function ()
      if not packer_plugins["nvim-treesitter"].loaded then
        print("treesitter not ready")
        packer_plugins["nvim-treesitter"].loaded = true
        require"packer".loader("nvim-treesitter")
      end
      require("nvim-gps").setup({
        disable_icons = false,           -- Setting it to true will disable all icons
        icons = {
          ["class-name"] = ' ',      -- Classes and class-like objects
          ["function-name"] = ' ',   -- Functions
          ["method-name"] = ' ',     -- Methods (functions inside class-like objects)
          ["container-name"] = ' ',  -- Containers (example: lua tables)
          ["tag-name"] = '炙'         -- Tags (example: html tags)
        },
      })
    end
  }
  use {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    config = function ()
      local map = require('core.utils').map
      map("n", "<C-x>u", ":UndotreeToggle | UndotreeFocus<CR>")
    end
  }
  use {
    'nvim-treesitter/nvim-treesitter-textobjects',
    after = 'nvim-treesitter'
  }
  use {
    "akinsho/toggleterm.nvim",
    disable = true,
    config = function()
      require("custom.plugins.toggleterm")
    end
  }
  use {
    'voldikss/vim-floaterm',
    opt = false,
    config = function ()
      require("custom.plugins.floaterm")
    end
  }
  use {
    -- after = 'telescope.nvim', -- do not lazy load telescope extensions, will cause bugs: module not found
    'dhruvmanila/telescope-bookmarks.nvim',
  }
  use {
    "AckslD/nvim-neoclip.lua",
    -- after = 'telescope.nvim', -- do not lazy load telescope extensions, will cause bugs: module not found
    config = function()
      require('neoclip').setup()
      vim.cmd([[inoremap <C-p> <cmd>Telescope neoclip<CR>]])
    end
  }
  use {
    "tpope/vim-scriptease"
  }
end
)

vim.g.matchup_surround_enabled = 1
vim.g.matchup_text_obj_enabled = 1

local lazy_timer = 50
function LazyLoad()
  local loader = require"packer".loader
  _G.PLoader = loader
  loader('nvim-cmp cmp-cmdline vim-matchup gitsigns.nvim telescope.nvim nvim-lspconfig')

end
vim.cmd([[autocmd User LoadLazyPlugin lua LazyLoad()]])
vim.defer_fn(function()
  vim.cmd([[doautocmd User LoadLazyPlugin]])
end, lazy_timer)

-- vim.cmd [[
--   autocmd VimEnter lua require('custom.plugins.cmp')
-- ]]

require("custom.autocmd")
