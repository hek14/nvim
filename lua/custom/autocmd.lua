vim.cmd [[
 au BufRead * set foldlevel=99
 autocmd BufRead *.py nmap <buffer> gm <Cmd>lua require('contrib.treesitter.python').goto_python_main()<cr>
 " autocmd BufWinEnter * if &buftype =~? '\(terminal\|prompt\|nofile\)' echom 'hello'
 function! TerminalOptions()
   silent! nnoremap <buffer> <C-g> :call Toggle_start_insert_terminal()<CR> 
   silent! inoremap <buffer> <C-g> <cmd>call Toggle_start_insert_terminal()<CR>
   silent! xnoremap <buffer> <C-g> <cmd>call Toggle_start_insert_terminal()<CR>
   silent! nnoremap <buffer> cc a<C-u>
   silent! inoremap <buffer> <silent> <C-w>n <Esc><C-w>j
   silent! inoremap <buffer> <silent> <C-w>e <Esc><C-w>k
   silent! inoremap <buffer> <silent> <C-w>i <Esc><C-w>l
   silent! tnoremap <buffer> <silent> Q <C-\><C-n>:q<CR>
   silent! au BufEnter,BufWinEnter,WinEnter <buffer> if &ft !~? "\(UltestOutput\)" | startinsert! | endif
   silent! au BufLeave <buffer> stopinsert!
   if &ft !~? "\(UltestOutput\)" 
     echomsg "not ultestoutput: " . filename()
     startinsert
   endif
 endfunction
 au TermOpen * call TerminalOptions()
 autocmd BufWinEnter,BufEnter,WinEnter * if &ft=='qf' | nnoremap <buffer> <silent> q :q<CR> | endif
 " Return to last edit position when opening files (You want this!)
 autocmd BufReadPost *
       \ if line("'\"") > 0 && line("'\"") <= line("$") |
       \   exe "normal! g`\"" |
       \ endif
 autocmd BufWinEnter,BufEnter,WinEnter,WinNew * if &ft=="TelescopePrompt" | startinsert | endif
 autocmd FileType lua setlocal shiftwidth=2
 autocmd User PackerComplete lua require("notify")("Packer Sucessful")
 autocmd User PackerCompileDone lua require("notify")("Packer Sucessful")
 autocmd FileType qf nnoremap <buffer> <C-p> <cmd>lua require('custom.utils').preview_qf()<CR>
]]
