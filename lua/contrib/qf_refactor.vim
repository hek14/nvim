function! s:replace_line(line, item) abort
  let bufnr = a:item['bufnr']
  let lnum = a:item['lnum']

  call bufload(bufname(bufnr))

  call setbufline(bufnr, lnum, a:line)
endfunction

function! s:extract_file_line(line) abort
  let res = {}

  let items = a:line->split('|')
  let res['bufnr'] = bufnr(items[0])
  let res['lnum'] = items[1]->matchstr('^\d\+')
  let res['text'] = getbufoneline(res['bufnr'], res['lnum'])

  return res
endfunction

function! s:update_buffers(buffers) abort
  10new
  for nr in keys(a:buffers)
    execute printf("%dbuffer +update", nr)
  endfor
  close
endfunction

function! qf_refactor#replace() abort
  let qf_lines = getline(1, '$')
  let qf_list = getqflist()

  let buffers = {}
  for line in qf_lines
    let sep_pat = '| '

    let idx = match(line, sep_pat)
    if idx <= 0
      continue
    endif

    let item = s:extract_file_line(line[:idx])

    let modified_line = line[idx + len(sep_pat):]
    let modified_line = matchstr(item['text'], '^\s\+') . modified_line
    if modified_line == item['text']
      continue
    endif

    let buffers[item['bufnr']] = 1
    call s:replace_line(modified_line, item)
  endfor

  call s:update_buffers(buffers)
  " execute "silent cfdo update"
endfunction
