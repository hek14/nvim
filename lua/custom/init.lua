local os_name = vim.loop.os_uname().sysname
_G.is_mac = os_name == 'Darwin'
_G.is_linux = os_name == 'Linux'
_G.is_windows = os_name == 'Windows'
_G.diagnostic_choice = "telescope" -- telescope or Trouble

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
map("n", "<leader>cd", "<cmd>lua Smart_current_dir()<cr>", {silent = false}) -- example to delete the buffer
map("x", ">", ">gv", {silent = false, noremap = true})
map("x", "<", "<gv", {silent = false, noremap = true})
map("n", "<leader>rr", "<cmd>lua require('telescope.builtin').resume()<CR>")
map("t", "<C-w>n", "<C-\\><C-n><C-w>j")
map("t", "<C-w>e", "<C-\\><C-n><C-w>k")
map("t", "<C-w>i", "<C-\\><C-n><C-w>l")
map("n", "<Up>", "5<C-w>+")
map("n", "<Down>", "5<C-w>-")
map("n", "<left>", "5<C-w><")
map("n", "<right>", "5<C-w>>")
map("n", "<Esc>", ":lua Closing_float_window()<CR>:noh<CR>")
map("n", "<leader>mc", "<cmd>Messages clear<CR>")
map("n", "<leader>mm", "<cmd>Messages<CR>")

vim.cmd [[
  cmap <C-a> <Home>
  cmap <C-e> <End>
  cmap <C-f> <Right>
  cmap <C-b> <Left>
  cnoremap <C-t> <C-f>
]]

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
function LazyLoad()
    local loader = require"packer".loader
    _G.PLoader = loader
    loader('nvim-cmp cmp-cmdline gitsigns.nvim telescope.nvim nvim-lspconfig')
end
vim.cmd([[autocmd User LoadLazyPlugin lua LazyLoad()]])
vim.defer_fn(function() vim.cmd([[doautocmd User LoadLazyPlugin]]) end,lazy_timer)

-- vim.cmd [[
--   autocmd VimEnter lua require('custom.pluginConfs.cmp')
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
  xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
  function! ExecuteMacroOverVisualRange()
    echo "@".getcmdline()
    execute ":'<,'>normal @".nr2char(getchar())
  endfunction
]]
require("custom.autocmd")
