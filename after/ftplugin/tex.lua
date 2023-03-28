local map = require("core.utils").map
local timer = vim.loop.new_timer()
local map_reset = false
local running = true
-- vim.defer_fn(function()
--   print('should override vimtex keymap')
--   pcall(function ()
--     vim.cmd [[
--     xunmap <buffer> ic
--     xunmap <buffer> ie
--     xunmap <buffer> im
--     xunmap <buffer> iP
--     xunmap <buffer> i$
--     xunmap <buffer> id
--     nunmap <buffer> ]c
--     nunmap <buffer> [c
--     ]]
--   end)
--   map('n',',t',':VimtexCompileSS<CR>',{buffer=true})
--   map('n',',v',':VimtexView<CR>',{buffer=true})
-- end,50)

map('x', 'ud', '<plug>(vimtex-id)',{buffer=true})
map('x', 'ad', '<plug>(vimtex-ad)',{buffer=true})
map('o', 'ud', '<plug>(vimtex-id)',{buffer=true})
map('o', 'ad', '<plug>(vimtex-ad)',{buffer=true})
map('x', 'u$', '<plug>(vimtex-i$)',{buffer=true})
map('x', 'a$', '<plug>(vimtex-a$)',{buffer=true})
map('o', 'u$', '<plug>(vimtex-i$)',{buffer=true})
map('o', 'a$', '<plug>(vimtex-a$)',{buffer=true})
map('x', 'uP', '<plug>(vimtex-iP)',{buffer=true})
map('x', 'aP', '<plug>(vimtex-aP)',{buffer=true})
map('o', 'uP', '<plug>(vimtex-iP)',{buffer=true})
map('o', 'aP', '<plug>(vimtex-aP)',{buffer=true})
map('x', 'um', '<plug>(vimtex-im)',{buffer=true})
map('x', 'am', '<plug>(vimtex-am)',{buffer=true})
map('o', 'um', '<plug>(vimtex-im)',{buffer=true})
map('o', 'am', '<plug>(vimtex-am)',{buffer=true})
map('x', 'ue', '<plug>(vimtex-ie)',{buffer=true})
map('x', 'ae', '<plug>(vimtex-ae)',{buffer=true})
map('o', 'ue', '<plug>(vimtex-ie)',{buffer=true})
map('o', 'ae', '<plug>(vimtex-ae)',{buffer=true})
map('x', 'uc', '<plug>(vimtex-ic)',{buffer=true})
map('x', 'ac', '<plug>(vimtex-ac)',{buffer=true})
map('o', 'uc', '<plug>(vimtex-ic)',{buffer=true})
map('o', 'ac', '<plug>(vimtex-ac)',{buffer=true})
