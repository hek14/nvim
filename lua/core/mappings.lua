local ft_map = require("core.autocmds").ft_map

local utils = require "core.utils"

local map_wrapper = utils.map

local cmd = vim.cmd

-- This is a wrapper function made to disable a plugin mapping from chadrc
-- If keys are nil, false or empty string, then the mapping will be not applied
-- Useful when one wants to use that keymap for any other purpose
local map = function(...)
  local keys = select(2, ...)
  if not keys or keys == "" then
    return
  end
  map_wrapper(...)
end


-- these mappings will only be called during initialization
local colemak = function ()
  local lhs = "neilukj"
  local rhs = "jkluine"
  local modes = {"n", "x", "o"}
  local opt = {silent = true, noremap = true}
  for i = 1, #lhs do
    local colemak = lhs:sub(i, i)
    local qwerty = rhs:sub(i, i)
    for _, mode in ipairs(modes) do
      vim.api.nvim_set_keymap(mode, colemak, qwerty, opt)
      vim.api.nvim_set_keymap(mode, vim.fn.toupper(colemak),
      vim.fn.toupper(qwerty), opt)
      if i < 4 then -- for direction keys
        vim.api.nvim_set_keymap(mode, "<C-w>" .. colemak, "<C-w>" .. qwerty,
        opt)
        vim.api.nvim_set_keymap(mode, "<C-w><C-" .. colemak .. ">",
        "<C-w><C-" .. qwerty .. ">", opt)
      end
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
  map("", "<Down>", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', { expr = true })
  map("", "<Up>", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', { expr = true })

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
  -- map_wrapper({ "n", "v" }, "x", '"_x')

  -- don't yank text on delete ( dd )
  -- map_wrapper({ "n", "v" }, "d", '"_d')

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
  map("n", "<F1>", "<Tab>", {noremap=true}) -- because I set <Ctrl-I> to send the same escape bytes as <Home>, so <Tab>/<Ctrl-I> can be used with this keymap
  map("x", ">", ">gv", {silent = false, noremap = true})
  map("x", "<", "<gv", {silent = false, noremap = true})
  map("t", "<C-w>n", "<C-\\><C-n><C-w>j")
  map("t", "<C-w>e", "<C-\\><C-n><C-w>k")
  map("t", "<C-w>i", "<C-\\><C-n><C-w>l")
  map("t", "<S-Space>", "<Space>",{noremap=true})
  map("n", "<Up>", "5<C-w>+")
  map("n", "<Down>", "5<C-w>-")
  map("n", "<left>", "5<C-w><")
  map("n", "<right>", "5<C-w>>")
  map("n", "<Esc>", [[:noh <Bar> :lua require('core.utils').closing_float_window()<CR>]])
  map("n", "<leader>mc", "<cmd>Messages clear<CR>")
  vim.cmd([[nmap <leader>mm :<C-u>Messages<CR>20 <C-w>+]])
  ft_map({'lua','vim'}, "n", ",t", "<Cmd>lua require('core.utils').source_curr_file()<cr>")
  map("n","<leader>ls",":SymbolsOutline<CR>")

  -- map("i", "<C-n>", "<C-O>o",{noremap = true})
  -- map("i", "<C-e>", "<C-O>O",{noremap = true})

  map("n", "N","mzJ`z")
  map("n", "k","nzzzv")
  map("n", "K","Nzzzv")
  -- swap line up and down
  map("n", "<leader>j", "<Esc>:m .+1<CR>==")
  map("n", "<leader>k", "<Esc>:m .-2<CR>==")
  map("n",'<leader>tv', ":lua require('core.utils')<CR> | :lua back_to_future()<CR>")
  -- NOTE: a good example of a senmantic mapping that need some evaluation
  vim.keymap.set("n", "<leader>sw", function ()
    local cword = vim.fn.expand("<cword>")
    local cmd_str = string.format([[:<C-u>%%s/\<%s\>//g<Left><Left>]],cword)
    return cmd_str
  end,{expr=true})

  map("s","A","<Esc>A")
  map("s","U","<Esc>i")

  map("n", '<leader>x', ":lua require('core.utils').close_buffer() <CR>") -- close  buffer
  map("n", "<M-c>", ":%y+ <CR>") -- copy whole file content
  map("n", "<S-t>", ":enew <CR>") -- new buffer
  map("n", "<C-t>b", ":tabnew <CR>") -- new tabs
  map("n", "<leader>n", ":set nu! <CR>")
  map("n", "<leader>rn", ":set rnu! <CR>") -- relative line numbers
  map("n", "<C-s>", ":w <CR>") -- ctrl + s to save file

  -- terminal mappings --
  -- get out of terminal mode
  map("t", "jj" , "<C-\\><C-n>")
  -- spawns terminals
  map("n", "<leader>th",":execute 15 .. 'new +terminal' | let b:term_type = 'hori' | startinsert <CR>")
  map("n", "<leader>tv", ":execute 'vnew +terminal' | let b:term_type = 'vert' | startinsert <CR>")
  map("n", "<leader>tw", ":execute 'terminal' | let b:term_type = 'wind' | startinsert <CR>")
  -- terminal mappings end --

  map("c", '<C-a>','<Home>')
  map("c", '<C-e>','<End>')
  map("c", '<C-f>','<Right>')
  map("c", '<C-b>','<Left>')
  map("c", '<C-p>','<Up>')
  map("c", '<C-n>','<Down>')
  map("c", '<C-t>','<C-f>')
  -- ft_map("python",'n','<leader>p',[[:lua vim.env['CUDA_VISIBLE_DEVICES']=''<Left>]])
  -- BUG: why does my utils.map doesn't work
  vim.keymap.set("n","<leader>p",[[:lua vim.env['CUDA_VISIBLE_DEVICES']=''<Left>]],{noremap=true})

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

  vim.cmd([[
  function! Cabbrev(key, value) abort
  execute printf('cabbrev <expr> %s (getcmdtype() == ":" && getcmdpos() <= %d) ? %s : %s',
  \ a:key, 1+len(a:key), Single_quote(a:value), Single_quote(a:key))
  endfunction

  function! Single_quote(str) abort
  return "'" . substitute(copy(a:str), "'", "''", 'g') . "'"
  endfunction

  call Cabbrev('pi', 'PackerInstall')
  call Cabbrev('pud', 'PackerUpdate')
  call Cabbrev('pc', 'PackerCompile')
  call Cabbrev('ps', 'PackerSync')
  call Cabbrev('li', 'let i =1 \|')
  call Cabbrev('py', 'PYTHON')
  call Cabbrev('lg', 'Lazygit')
  call Cabbrev('ft', 'FloatermNew')
  xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
  function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
  endfunction
  ]])
  -- Add Packer commands because we are not loading it at startup
  cmd "silent! command! PackerClean lua require 'plugins' require('packer').clean()"
  cmd "silent! command! PackerCompile lua require 'plugins' require('packer').compile()"
  cmd "silent! command! PackerInstall lua require 'plugins' require('packer').install()"
  cmd "silent! command! PackerStatus lua require 'plugins' require('packer').status()"
  cmd "silent! command! PackerSync lua require 'plugins' require('packer').sync()"
  cmd "silent! command! PackerUpdate lua require 'plugins' require('packer').update()"
end

others()
colemak()
vim.cmd [[
  nnoremap n gj
  nnoremap e gk
]]
