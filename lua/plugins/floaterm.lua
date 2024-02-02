local M =  {
  "voldikss/vim-floaterm",
  lazy = false,
  enabled = false
}

function M.init()
  local map = require('core.utils').map
  vim.cmd[[command! PYTHON FloatermNew python]]
  vim.cmd[[command! Lazygit FloatermNew --height=0.8 --width=0.8 lazygit]]
  map("n", ",ts", "<cmd>FloatermNew --wintype=split --height=0.3 <CR>")
  vim.g.floaterm_keymap_new = ",tn"
  vim.g.floaterm_keymap_toggle = ",tt"
  vim.g.floaterm_keymap_next = ",n"
  vim.g.floaterm_keymap_prev = ",p"
  vim.g.floaterm_keymap_kill = ",tk"
  vim.g.floaterm_autoinsert = true
  vim.cmd([[
    function! Floaterm_open_in_normal_window() abort
    let f = findfile(expand('<cfile>'))
    if !empty(f) && has_key(nvim_win_get_config(win_getid()), 'anchor')
      FloatermHide
      execute 'e ' . f
      endif
      endfunction
      autocmd FileType floaterm nnoremap <silent><buffer> gf :call Floaterm_open_in_normal_window()<CR>
      ]])
  vim.cmd([[
    function! Floaterm_toggleOrCreateTerm(bang, name) abort
    if a:bang
      call floaterm#toggle(a:bang, -1, a:name)
      endif
      if !empty(a:name)
        let bufnr = floaterm#terminal#get_bufnr(a:name)
        if bufnr == -1
          execute('FloatermNew --name='.a:name)
        else
          call floaterm#toggle(a:bang, bufnr, a:name)
          endif
        else
          call floaterm#util#show_msg('Name is empty')
          endif
          endfunction
          command! -nargs=? -bang -complete=customlist,floaterm#cmdline#complete
          \ FloatermToggleOrCreate call Floaterm_toggleOrCreateTerm(<bang>0, <q-args>)
          ]])
end
return M
