vim.cmd [[
 au BufRead * set foldlevel=99
 autocmd BufRead *.py nmap <buffer> gm /^if.*__main__<cr> :noh <cr> 0
 " autocmd BufWinEnter * if &buftype =~? '\(terminal\|prompt\|nofile\)' echom 'hello'
 function! Toggle_start_insert_terminal()
    if g:terminal_start_insert == 1
      let g:terminal_start_insert = 0
    else
      let g:terminal_start_insert = 1
    endif
    echom "Toggle startinsert: " . g:terminal_start_insert
 endfunction
 function! TerminalOptions()
   let g:terminal_start_insert=1 
   let l:bufnr = bufnr()
   silent! nnoremap <buffer> <C-g> :call Toggle_start_insert_terminal()<CR> 
   silent! inoremap <buffer> <C-g> <cmd>call Toggle_start_insert_terminal()<CR>
   silent! xnoremap <buffer> <C-g> <cmd>call Toggle_start_insert_terminal()<CR>
   silent! nnoremap <buffer> cc a<C-u>
   silent! inoremap <buffer> <silent> <C-w>n <Esc><C-w>j
   silent! inoremap <buffer> <silent> <C-w>e <Esc><C-w>k
   silent! inoremap <buffer> <silent> <C-w>i <Esc><C-w>l
   silent! tnoremap <buffer> <silent> Q <C-\><C-n>:q<CR>
   silent! au BufEnter,BufWinEnter,WinEnter <buffer> startinsert!
   silent! au BufLeave <buffer> stopinsert!
   startinsert
 endfunction
 au TermOpen * call TerminalOptions()
 autocmd BufWinEnter,BufEnter,WinEnter * if &filetype=="dap-repl" | startinsert | endif
 autocmd BufWinEnter,BufEnter,WinEnter * if &ft=='qf' | nnoremap <buffer> <silent> q :q<CR> | endif
 " Return to last edit position when opening files (You want this!)
 autocmd BufReadPost *
       \ if line("'\"") > 0 && line("'\"") <= line("$") |
       \   exe "normal! g`\"" |
       \ endif
]]
