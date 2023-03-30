" https://github.com/tpope/vim-scriptease
" Section: :Messages
function! scriptease#capture(excmd) abort
  try
    redir => out
    exe 'silent! '.a:excmd
  finally
    redir END
  endtry
  return out
endfunction

function! s:filereadable(path) abort
  return s:fcall('filereadable', a:path)
endfunction

function! scriptease#messages_command(bang, count, arg) abort
  let command = (a:count > -1 ? a:count : '') . 'messages'
  if !empty(a:arg)
    return command . ' ' . a:arg
  endif
  let qf = []
  let virtual = get(g:, 'virtual_scriptnames', {})
  for line in split(scriptease#capture(command), '\n\+')
    let lnum = matchstr(line, '\C^line\s\+\zs\d\+\ze:$')
    if lnum && len(qf) && qf[-1].text =~# ':$'
      let qf[-1].text = substitute(qf[-1].text, ':$', '[' . lnum . ']:', '')
    else
      call add(qf, {'text': line})
    endif
    let functions = matchstr(qf[-1].text, '\s\+\zs\S\+\]\ze:$')
    if empty(functions)
      continue
    endif
    let qf[-1].text = substitute(qf[-1].text, '\s\+\S\+:$', '', '')
    for funcline in split(functions, '\.\.')
      call add(qf, {'text': funcline})
      let lnum = matchstr(funcline, '\[\zs\d\+\ze\]$')
      let function = substitute(funcline, '\[\d\+\]$', '', '')
      if function =~# '[\\/.]' && s:filereadable(get(virtual, function, function))
        let qf[-1].filename = get(virtual, function, function)
        let qf[-1].lnum = lnum
        let qf[-1].text = ''
        continue
      elseif function =~# '^\d\+$'
        let function = '{' . function . '}'
      endif
      let list = &list
      try
        set nolist
        let output = split(scriptease#capture('verbose function '.function), "\n")
      finally
        let &list = list
      endtry
      let filename = expand(matchstr(get(output, 1, ''), 'from \zs.*'))
      let filename = substitute(filename, ' \S\+ \d\+$', '', '')
      let filename = get(virtual, filename, filename)
      if !s:filereadable(filename)
        let qf[-1].text .= string(filename)
        continue
      endif
      let implementation = map(output[2:-2], 'v:val[len(matchstr(output[-1],"^ *")) : -1]')
      call map(implementation, 'v:val ==# " " ? "" : v:val')
      let body = []
      let offset = 0
      for line in s:readfile(filename)
        if line =~# '^\s*\\' && !empty(body)
          let body[-1][0] .= s:sub(line, '^\s*\\', '')
          let offset += 1
        else
          call extend(body, [[s:gsub(line, "\t", repeat(" ", &tabstop)), offset]])
        endif
      endfor
      for j in range(len(body)-len(implementation)-2)
        if function =~# '^{'
          let pattern = '.*\.'
        elseif function =~# '^<SNR>'
          let pattern = '\%(s:\|<SID>\)' . matchstr(function, '_\zs.*') . '\>'
        else
          let pattern = function . '\>'
        endif
        if body[j][0] =~# '\C^\s*fu\%[nction]!\=\s*'.pattern
              \ && (body[j + len(implementation) + 1][0] =~# '\C^\s*endf'
              \ && map(body[j+1 : j+len(implementation)], 'v:val[0]') ==# implementation
              \ || pattern !~# '\*')
          let qf[-1].filename = filename
          let qf[-1].lnum = j + body[j][1] + lnum + 1
          let qf[-1].valid = 1
          let found = 1
          break
        endif
      endfor
    endfor
  endfor
  call setqflist(qf)
  if exists(':chistory')
    call setqflist([], 'r', {'title': ':Messages'})
  endif
  copen
  call nvim_buf_set_var(0,"is_message",v:true)
  $
  call search('^[^|]', 'bWc')
  return ''
endfunction
let s:othercmd = has('patch-8.1.560') || has('nvim-0.5') ? 'command! -addr=other' : 'command!'
exe s:othercmd '-bar -bang -nargs=? -range=-1 Messages'
      \ 'exe scriptease#messages_command(<bang>0, <count>, <q-args>)'
