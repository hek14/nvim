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

local map = require('core.utils').map
map("n", "<space>", "<Nop>", {noremap = true, silent = true})
map("n", "<leader>cd", "<cmd>lua Smart_current_dir()<cr>", {silent = false}) -- example to delete the buffer
map("x", ">", ">gv", {silent = false, noremap = true})
map("x", "<", "<gv", {silent = false, noremap = true})
map("n", "<leader>rr", "<cmd>lua require('telescope.builtin').resume()<CR>")
map("t", "<C-w>n", "<C-\\><C-n><C-w>j")
map("t", "<C-w>e", "<C-\\><C-n><C-w>k")
map("t", "<C-w>i", "<C-\\><C-n><C-w>l")
map("t", "<S-Space>", "<Space>",{noremap=true})
map("n", "<Up>", "5<C-w>+")
map("n", "<Down>", "5<C-w>-")
map("n", "<left>", "5<C-w><")
map("n", "<right>", "5<C-w>>")
map("n", "<Esc>", ":lua Closing_float_window()<CR>:noh<CR>")
map("n", "<leader>mc", "<cmd>Messages clear<CR>")
map("n", "<leader>mm", "<cmd>Messages<CR>")
map("n", ",t", "<Cmd>lua Source_curr_file()<cr>")

map("i", "<C-n>", "<C-O>o",{noremap = true})
map("i", "<C-e>", "<C-O>O",{noremap = true})

vim.cmd [[
  cmap <C-a> <Home>
  cmap <C-e> <End>
  cmap <C-f> <Right>
  cmap <C-b> <Left>
  cnoremap <C-t> <C-f>
]]

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
]])

function Smart_current_dir()
    local fname = vim.api.nvim_buf_get_name(0)
    local dir = require('lspconfig').util.find_git_ancestor(fname) or
                    vim.fn.expand('%:p:h')
    vim.cmd("cd " .. dir)
end

function Closing_float_window()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(win)
        if config.relative ~= "" then
            vim.api.nvim_win_close(win, false)
            print('Closing window', win)
        end
    end
end

-- vim.tbl_contains to check whether an item is in a table

function Source_curr_file()
    if vim.bo.ft == "lua" then
        vim.cmd [[luafile %]]
    elseif vim.bo.ft == "vim" then
        vim.cmd [[so %]]
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
    for i, var in ipairs(args) do
        if i > 1 then
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

local lazy_timer = 50
local function LazyLoad() -- not necessary to use global function for nvim_create_autocmd
  local loader = require"packer".loader
  _G.PLoader = loader
  loader('nvim-cmp cmp-cmdline telescope.nvim') -- the vanilla 'require("nvim-cmp")' will not work here
  require("luasnip/loaders/from_vscode").load()
  vim.defer_fn(function ()
    require("plugins") -- require the plugin config, although the command PackerCompile will require this
  end,50)
  -- method 1 of loading a packer configed package: dominated by packer(event,ft,module,key,command, etc. all lazy but automatically)
  -- method 2 of loading a packer configed package: manually load the package using the packer.loader just like above
  -- using the packer's loader instead of vanilla require, the config part of each package powered by packer.nvim will still work
end
local group = vim.api.nvim_create_augroup("kk_LazyLoad",{clear=true})
vim.api.nvim_create_autocmd("User",{pattern="LazyLoad",callback=LazyLoad,group=group}) -- NOTE: autocmd User xxx, xxx is the pattern
vim.defer_fn(function() vim.cmd([[doautocmd User LazyLoad]]) end,lazy_timer)
-- the LazyLoad function will be called after custom/init.lua and plugin/packer_compiled.lua (you can add print to check this) because of the defer_fn
-- defer_fn target will wait until the end of current context(here: is the nvim init process)
-- to further understand the defer_fn: it's a one-shot timer, and the target function is automatically schedule_wrapped
-- vim.defer_fn(function ()
--   vim.defer_fn(function ()
--     print("in the inner defer_fn")
--   end,0)
--   print('testing defer_fn 1')
--   print('testing defer_fn 2')
--   print('ending the defer_fn')
-- end,0)
-- print("the main function")

vim.cmd [[set viminfo+=:2000]]
vim.cmd [[
  xnoremap ul g_o^
  onoremap ul :normal vul<CR>
  xnoremap al $o0
  onoremap al :normal val<CR>
  xnoremap u% GoggV
  onoremap u% :normal vu%<CR>
]]

-- setup clipboard
vim.cmd [[
  set clipboard+=unnamed,unnamedplus
  let g:clipboard = {
      \   'name': 'ClippyRemoteClipboard',
      \   'copy': {
      \      '+': 'clippy set',
      \      '*': 'clippy set',
      \    },
      \   'paste': {
      \      '+': 'clippy get',
      \      '*': 'clippy get',
      \   },
      \   'cache_enabled': 0,
      \ }
]]

vim.cmd [[
  " goodies: select the last pasted text
  nnoremap <expr> gp '`[' . strpart(getregtype(), 0, 1) . '`]'
  xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
  function! ExecuteMacroOverVisualRange()
    echo "@".getcmdline()
    execute ":'<,'>normal @".nr2char(getchar())
  endfunction
  " " example of how to create a new hightlight:
  hi def KK_init guibg=grey guifg=blue gui=italic
  highlight TSDefinitionUsage guibg=#444444 " NOTE: highlight used in treesitter-refactor
  " " example of how to set a existing hightlight:
  " " for GUI nvim(iTerm,kitty,etc.):
  " hi Search gui=italic guibg=peru guifg=wheat
  " " for terminal nvim:
  " hi Search cterm=NONE ctermfg=grey ctermbg=blue
  " " def a highlight by linking
  " hi def link Search Todo
]]
require("custom.autocmd")

map('i','<C-x><C-l>','<Cmd>lua R("contrib.treesitter.python").fast_signature()<CR>')
map('i','<C-x><C-g>','<Cmd>lua R("contrib.treesitter.python").fast_init_class()<CR>')
vim.cmd[[packadd cfilter]]
