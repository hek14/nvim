local ft_map = require("core.autocmds").ft_map

local utils = require "core.utils"

local map = utils.map

local cmd = vim.cmd

-- these mappings will only be called during initialization
local colemak = function ()
  local lhs = "neilukj"
  local rhs = "jkluine"
  local modes = "nxo"
  for i = 1, #lhs do
    local colemak = lhs:sub(i, i)
    local qwerty = rhs:sub(i, i)
    map(modes, colemak, qwerty)
    map(modes, vim.fn.toupper(colemak),vim.fn.toupper(qwerty))
    if i < 4 then
      map(modes, "<C-w>" .. colemak, "<C-w>" .. qwerty)
      map(modes, "<C-w><C-" .. colemak .. ">", "<C-w><C-" .. qwerty .. ">")
    end
  end
end

local function others()
  -- Don't copy the replaced text after pasting in visual mode
  map("v", "p", "p:let @+=@0<CR>")

  -- Allow moving the cursor through wrapped lines with j, k, <Up> and <Down>
  -- http://www.reddit.com/r/vim/comments/2k4cbr/problem_with_gj_and_gk/
  -- empty mode is same as using :map
  -- also don't use g[j|k] when in operator pending mode, so it doesn't alter d, y or c behaviour
  map({ "n", "x", "o" }, "j", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', { expr = true })
  map({ "n", "x", "o" }, "k", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', { expr = true })
  map("n", "<Down>", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', { expr = true })
  map("n", "<Up>", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', { expr = true })

  map("i", "<C-q>",function ()
    if vim.g.cmp_enabled then
      require("cmp").close()
      vim.g.cmp_enabled = false
    else
      require('cmp').complete()
      vim.g.cmp_enabled = true
    end
  end)
  -- don't yank text on cut ( x )
  -- map({ "n", "v" }, "x", '"_x')

  -- don't yank text on delete ( dd )
  -- map({ "n", "v" }, "d", '"_d')

  -- navigation within insert mode
  map("i", "<C-b>", "<Left>")
  map("i", "<C-f>", "<Right>")
  map("i", "<C-a>", "<ESC>^i")
  map("i", "<C-e>", "<End>")
  map("i", "<C-n>", "<Down>")
  map("i", "<C-p>", "<Up>")

  map("n", ',s',require('core.utils').ScopeSearch)
  map("x", ',s',require('core.utils').ScopeSearch)

  map("n", "<leadr>ts", [[ :keeppatterns<Bar>:%s/\s\+$//e<CR> ]] )
  cmd [[ command! DeleteTrailSpace keeppatterns<Bar>%s/\s\+$//e<Bar>noh ]]
  map("n", "<space>", "<Nop>", {noremap = true, silent = true})
  map("n", "<leader>cd", [[<cmd>lua require('core.utils').smart_current_dir()<cr>]], {silent = false}) -- example to delete the buffer
  map("n", "<F1>", "<Tab>", {noremap=true}) -- because I set <Ctrl-I> to send the same escape bytes as <F1>, so <Tab>/<Ctrl-I> can be used with this keymap
  map("x", ">", ">gv", {silent = false, noremap = true})
  map("x", "<", "<gv", {silent = false, noremap = true})
  map("t", "<C-w>n", "<C-\\><C-n><C-w>j")
  map("t", "<C-w>e", "<C-\\><C-n><C-w>k")
  map("t", "<C-w>i", "<C-\\><C-n><C-w>l")
  map("t", "<S-Space>", "<Space>",{noremap=true})
  map("t", "jj" , "<C-\\><C-n>")
  local keycode = function (key)
    return vim.api.nvim_replace_termcodes(key,true,false,true)
  end
  map("t",'<C-s>',function ()
    vim.api.nvim_feedkeys(keycode('import numpy as np\n'),'n',false)
    vim.api.nvim_feedkeys(keycode('import torch\n'),'n',false)
    vim.api.nvim_feedkeys(keycode('import matplotlib.pyplot as plt\n'),'n',false)
  end,{desc = "insert frequent python package"})

  map("n", "<Up>", "5<C-w>+")
  map("n", "<Down>", "5<C-w>-")
  map("n", "<left>", "5<C-w><")
  map("n", "<right>", "5<C-w>>")
  map("n", "<C-q>", [[:noh <Bar> :lua require('core.utils').close_float_window()<CR>]])
  map("n", "<Esc>", [[:noh<CR>]])
  map("n", "<leader>mc", "<cmd>Messages clear<CR>")
  map("n","<leader>mm","<Cmd>Messages<CR>")

  ft_map({'lua','vim'}, "n", "<leader>so", "<Cmd>lua require('core.utils').source_curr_file()<cr>")
  map("n","<leader>ls",":SymbolsOutline<CR>")
  map("n",",q",":<C-u>cq 55<CR>")

  vim.api.nvim_create_user_command('FixImport',function ()
    local buf = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.buf_get_clients(buf)
    for id,client in pairs(clients) do
      if client.name~='null-ls' then
        client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
      end
    end
  end,{})
  map('n','<leader>pl',function ()
    print(package.loaded['cmp'])
  end,{silent=true})

  -- map("i", "<C-n>", "<C-O>o",{noremap = true})
  -- map("i", "<C-e>", "<C-O>O",{noremap = true})

  map("n", "N","mzJ`z")
  map("n", "k","nzzzv")
  map("n", "K","Nzzzv")
  -- swap line up and down
  map("n", "<leader>j", "<Esc>:m .+1<CR>==")
  map("n", "<leader>k", "<Esc>:m .-2<CR>==")
  map("n",'<leader>tv', ":lua require('core.utils')<CR> | :lua back_to_future()<CR>")
  map("n",",r", function ()
    local sub_word = require('contrib.my_sub_word').get_sub_word()
    return ":<C-u>s/"  .. sub_word .. "//g<Left><Left>"
  end,{expr=true,silent=false}) -- NOTE: should specify silent=false, because we need the cmdline to be appeared for <Left>
  map("n",",z", function ()
    local eval_name = require('core.utils').quick_eval()
    return eval_name .. '<Left>'
  end,{expr=true,silent=false})-- NOTE: should specify silent=false, because we need the cmdline to be appeared for <Left>
  map("n",'<leader>rr',require('contrib.my_better_substitute').my_better_substitute)
  -- line line_start line_end

  map("s","A","<Esc>A")
  map("s","U","<Esc>i")

  map("n", '<leader>x', ":lua require('core.utils').close_buffer() <CR>") -- close  buffer
  map("n", "<M-c>", ":%y+ <CR>") -- copy whole file content
  map("n", "<S-t>", ":enew <CR>") -- new buffer
  map("n", "<C-t>b", ":tabnew <CR>") -- new tabs
  -- map("n", "<leader>n", ":set nu! <CR>")
  map("n", "<leader>rn", ":set rnu! <CR>") -- relative line numbers
  map("n", "<C-s>", ":w! <CR>") -- ctrl + s to save file

  -- terminal mappings --
  -- get out of terminal mode
  -- spawns terminals
  map("n", "<leader>th",":execute 15 .. 'new +terminal' | let b:term_type = 'hori' | startinsert <CR>")
  map("n", "<leader>tv", ":execute 'vnew +terminal' | let b:term_type = 'vert' | startinsert <CR>")
  map("n", "<leader>tw", ":execute 'terminal' | let b:term_type = 'wind' | startinsert <CR>")
  -- terminal mappings end --

  -- map("c", '<C-a>','<Home>')
  -- map("c", '<C-e>','<End>')
  -- map("c", '<C-f>','<Right>')
  -- map("c", '<C-b>','<Left>')
  -- map("c", '<C-d>','<C-f>') -- using Telescope <>
  map("c", '<C-p>','<Up>')
  map("c", '<C-n>','<Down>')
  -- NOTE: <C-g> and <C-t> to forward and backward when search
  -- ft_map("python",'n','<leader>p',[[:lua vim.env['CUDA_VISIBLE_DEVICES']=''<Left>]])
  map("n","<leader>p",":lua vim.env['CUDA_VISIBLE_DEVICES']=''<Left>",{silent=false})

  map("x", "ul", "g_o^")
  map("o", "ul", ":normal vul<CR>")
  map("x", "al", "$o0")
  map("o", "al", ":normal val<CR>")
  map("x", "u%", "GoggV")
  map("o", "u%", ":normal vu%<CR>")

  map("n",'gp',[['`[' . strpart(getregtype(), 0, 1) . '`]']], {expr=true})

  map('i','<C-x><C-l>','<Cmd>lua require("contrib.treesitter.python").fast_signature()<CR>')
  map('i','<C-x><C-g>','<Cmd>lua require("contrib.treesitter.python").fast_init_class()<CR>')
  map('n','<leader>dt','<Cmd>lua require("contrib.my_diagnostic").toggle_line_diagnostic()<CR>')

  map("n", {"<TAB>","]b"}, ":bn<CR>")
  map("n", {"<S-Tab>","[b"}, ":bp<CR>")

  local escape = require('core.utils').termcode
  local function quick_insert_profile()
    vim.fn.feedkeys(escape('local start = vim.loop.hrtime()\n'),'n')
    vim.fn.setreg('v',[[print(string.format('spent time: %s ms',(vim.loop.hrtime()-start)/1000000))]])
  end
  map('i','<C-w>',quick_insert_profile)
  map('n','<C-p>',function()
    vim.cmd([[ :set buflisted | set nohidden ]])
    require('bufferline.ui').refresh()
  end,{desc='pin this buffer'})

  vim.cmd([[
  function! Cabbrev(key, value) abort
  execute printf('cabbrev <expr> %s (getcmdtype() == ":" && getcmdpos() <= %d) ? %s : %s',
  \ a:key, 1+len(a:key), Single_quote(a:value), Single_quote(a:key))
  endfunction

  function! Single_quote(str) abort
  return "'" . substitute(copy(a:str), "'", "''", 'g') . "'"
  endfunction

  call Cabbrev('LI', 'Lazy install')
  call Cabbrev('LU', 'Lazy update')
  call Cabbrev('LS', 'Lazy sync')
  call Cabbrev('LP', 'Lazy profile')
  call Cabbrev('LC', 'Lazy clean')
  call Cabbrev('li', 'let i =1 \|')
  call Cabbrev('lg', 'Lazygit')
  xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
  function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
  endfunction
  ]])
end

others()
colemak()
vim.cmd [[
  nnoremap n gj
  nnoremap e gk
]]
