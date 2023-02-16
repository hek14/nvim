local map = require("core.utils").map
vim.defer_fn(function()
  print('should override vimtex keymap')
  pcall(function ()
    vim.cmd [[
    xunmap <buffer> ic
    xunmap <buffer> ie
    xunmap <buffer> im
    xunmap <buffer> iP
    xunmap <buffer> i$
    xunmap <buffer> id
    nunmap <buffer> ]c
    nunmap <buffer> [c
    ]]
  end)
  map('n',',t',':VimtexCompileSS<CR>',{buffer=true})
  map('n',',v',':VimtexView<CR>',{buffer=true})
end,100)
