local lhs = "neilukj"
local rhs = "jkluike"
local modes = {"n","x","o"}
local opt = {silent=true,noremap=true}
for i = 1,#lhs do
  local colemak = lhs:sub(i,i)
  local qwerty  = rhs:sub(i,i)
  for _,mode in ipairs(modes) do
    vim.api.nvim_set_keymap(mode,colemak,qwerty,opt)
    vim.api.nvim_set_keymap(mode,vim.fn.toupper(colemak),vim.fn.toupper(qwerty),opt)
    if i < 4 then -- for direction keys
      vim.api.nvim_set_keymap(mode,"<C-w>" .. colemak,"<C-w>" .. qwerty,opt)
      vim.api.nvim_set_keymap(mode,"<C-w><C-" .. colemak .. ">","<C-w><C-" .. qwerty .. ">",opt)
    end
  end
end

local map = require('core.utils').map
map("n", "<leader>cd", "<cmd>:cd %:p:h<cr>", {silent=false}) -- example to delete the buffer
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
map("n","<Esc>", ":lua Closing_float_window()<CR>:noh<CR>")
map("n","<leader>mc","<cmd>Messages clear<CR>")
map("n","<leader>mm","<cmd>Messages<CR>")
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

function _G.P(...)
  local printResult = ""
  local sep = " "
  local args = {...}
  for i,var in ipairs(args) do
    if i>1 then
      printResult = printResult .. sep .. vim.inspect(var)
    else
      printResult = vim.inspect(var)
    end
  end
  print(printResult)
  -- vim.cmd[[10sp | drop ~/.cache/nvim/debug.log]]
  -- vim.api.nvim_buf_set_lines(0,-1,-1,true,{printResult})
  -- vim.cmd[[silent! w | normal! G]]
  return printResult
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
    "jose-elias-alvarez/null-ls.nvim",
    after = 'nvim-lspconfig',
    config = function ()
      require("null-ls").setup({
        sources = {
          require("null-ls").builtins.formatting.lua_format,
          require("null-ls").builtins.formatting.black,
        },
      })
    end
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
  use {
    'kevinhwang91/nvim-bqf', 
    config = function ()
      -- need this to use with quickfix-reflector
      vim.cmd [[
        augroup nvim-bqf-kk
          autocmd FileType qf lua vim.defer_fn(function() require('bqf').enable() end,50)
        augroup END
      ]]
    end
  }
  -- 3. editable qf (similar to emacs wgrep)
  use {
    'stefandtw/quickfix-reflector.vim',
    -- this plugin conflicts with the above nvim-bqf, it will cause nvim-bqf not working, there is two solutions:
    -- soluction 1: defer the nvim-bqf loading just like above
    -- solution 2: modify the quickfix-reflector.vim init_buffer like below:
    -- function! s:PrepareBuffer()
    --   try 
    --     lua require('bqf').enable()
    --   catch
    --     echom "nvim-bqf is not installed"
    --   endtry
    --   if g:qf_modifiable == 1
    --     setlocal modifiable
    --   endif
    --   let s:qfBufferLines = getline(1, '$')
    -- endfunction
  }
  -- 4. preview location
  use { 
    'ronakg/quickr-preview.vim',
    disable = true,
    config = function ()
      vim.g.quickr_preview_keymaps = 0
      vim.cmd [[
        augroup qfpreview
          autocmd!
          autocmd FileType qf nmap <buffer> p <plug>(quickr_preview)
          autocmd FileType qf nmap <buffer> q exe "normal \<plug>(quickr_preview_qf_close)<CR>"
        augroup END
      ]]
    end
  }

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
    'jvgrootveld/telescope-zoxide',
    setup = function ()
      require('core.utils').map("n", "<leader>z", ":Telescope zoxide list<CR>")
    end,
  }
  use { 
    "nvim-telescope/telescope-file-browser.nvim" 
  }
  use {
    "tpope/vim-scriptease"
  }
  use {
    disable = true, -- just use simple nui
    'ray-x/guihua.lua', 
    run = 'cd lua/fzy && make'
  }
  use {
    'MunifTanjim/nui.nvim'
  }
  use {
    'danilamihailov/beacon.nvim'
  }
end
)

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
vim.cmd [[set viminfo+=:2000]]
vim.cmd [[
  xnoremap ul g_o^
  onoremap ul :normal vul<CR>
  xnoremap al $o0
  onoremap al :normal val<CR>
  xnoremap u% GoggV
  onoremap u% :normal vu%<CR>
]]

vim.cmd [[
  xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
  function! ExecuteMacroOverVisualRange()
    echo "@".getcmdline()
    execute ":'<,'>normal @".nr2char(getchar())
  endfunction
]]
require("custom.autocmd")
