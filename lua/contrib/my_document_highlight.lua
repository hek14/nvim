local uv = vim.loop
local protocol = require('vim.lsp.protocol')
local highlight = require('vim.highlight')
local fmt = string.format
local log = require('core.utils').log
local group = vim.api.nvim_create_augroup('kk_highlight',{clear=true})

-- ========== state
local M = {}
local curr_references = {}
local reference_mark_group = {}
local last_clear = {}
local last_highlight = {}
local clear_by_autocmd = {}
local profile_time = {}
local colors = {
  "#C70039",
  "#a89984",
  "#b16286",
  "#d79921",
  "#1F6C4A",
  "#d65d0e",
  "#458588",
  '#aeee00',
  '#ff0000',
  '#0000ff',
  '#b88823',
  '#ffa724',
  '#ff2c4b'
}
-- ========== state end

for i, color in ipairs(colors) do
  vim.cmd (fmt('highlight! def kk_highlight_%s_write gui=italic,bold guibg=%s guifg=black',i,color))
  vim.cmd (fmt('highlight! def kk_highlight_%s_read guibg=%s guifg=black',i,color))
end
local color_index = 0
local hl_offset_encoding = "utf-16"


---- ========== utils function
local function profile_start(bufnr)
  profile_time[bufnr] = os.clock()
end

local function profile_end(bufnr,name)
  log(fmt("Profile %s: %s",name,os.clock()-profile_time[bufnr]))
  profile_time[bufnr] = os.clock()
end

local function echo(hlgroup, msg)
  vim.cmd(fmt('echohl %s', hlgroup))
  vim.cmd(fmt('echo "[my_document_highlight] %s"', msg))
  vim.cmd('echohl None')
end

local function error(msg)
  echo('ErrorMsg: ', msg)
end

local function get_lines(bufnr, rows)
  rows = type(rows) == 'table' and rows or { rows }

  -- This is needed for bufload and bufloaded
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end

  ---@private
  local function buf_lines()
    local lines = {}
    for _, row in pairs(rows) do
      lines[row] = (vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false) or { '' })[1]
    end
    return lines
  end

  local uri = vim.uri_from_bufnr(bufnr)

  -- load the buffer if this is not a file uri
  -- Custom language server protocol extensions can result in servers sending URIs with custom schemes. Plugins are able to load these via `BufReadCmd` autocmds.
  if uri:sub(1, 4) ~= 'file' then
    vim.fn.bufload(bufnr)
    return buf_lines()
  end

  -- use loaded buffers if available
  if vim.fn.bufloaded(bufnr) == 1 then
    return buf_lines()
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)

  -- get the data from the file
  local fd = uv.fs_open(filename, 'r', 438)
  if not fd then
    return ''
  end
  local stat = uv.fs_fstat(fd)
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)

  local lines = {} -- rows we need to retrieve
  local need = 0 -- keep track of how many unique rows we need
  for _, row in pairs(rows) do
    if not lines[row] then
      need = need + 1
    end
    lines[row] = true
  end

  local found = 0
  local lnum = 0

  for line in string.gmatch(data, '([^\n]*)\n?') do
    if lines[lnum] == true then
      lines[lnum] = line
      found = found + 1
      if found == need then
        break
      end
    end
    lnum = lnum + 1
  end

  -- change any lines we didn't find to the empty string
  for i, line in pairs(lines) do
    if line == true then
      lines[i] = ''
    end
  end
  return lines
end

local function get_line(bufnr, row)
  return get_lines(bufnr, { row })[row]
end

local function _str_byteindex_enc(line, index, encoding)
  if not encoding then
    encoding = 'utf-16'
  end
  if encoding == 'utf-8' then
    if index then
      return index
    else
      return #line
    end
  elseif encoding == 'utf-16' then
    return vim.str_byteindex(line, index, true)
  elseif encoding == 'utf-32' then
    return vim.str_byteindex(line, index)
  else
    error('Invalid encoding: ' .. vim.inspect(encoding))
  end
end

local function get_line_byte_from_position(bufnr, position, offset_encoding)
  -- LSP's line and characters are 0-indexed
  -- Vim's line and columns are 1-indexed
  local col = position.character
  -- When on the first character, we can ignore the difference between byte and
  -- character
  if col > 0 then
    local line = get_line(bufnr, position.line) or ''
    local ok, result
    ok, result = pcall(_str_byteindex_enc, line, col, offset_encoding)
    if ok then
      return result
    end
    return math.min(#line, col)
  end
  return col
end

local function point_in_range(point, range)
    if point.row == range['start']['line'] and point.col < range['start']['character'] then
        return false
    end
    if point.row == range['end']['line'] and point.col > range['end']['character'] then
        return false
    end
    return point.row >= range['start']['line'] and point.row <= range['end']['line']
end

local function cursor_in_references(bufnr)
  if not curr_references[bufnr] then
    return false
  end
  if vim.api.nvim_win_get_buf(0) ~= bufnr then
    return false
  end
  local crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
  crow = crow - 1 -- reference ranges are (0,0)-indexed for (row,col)
  for _, reference in pairs(curr_references[bufnr]) do
    if point_in_range({row=crow,col=ccol}, reference.range) then
      return true
    end
  end
  return false
end

local function before_by_start(r1, r2)
  if r1['start'].line < r2['start'].line then return true end
  if r2['start'].line < r1['start'].line then return false end
  if r1['start'].character < r2['start'].character then return true end
  return false
end
---- ========== utils function end

local function my_buf_highlight_references(bufnr, _references)
  local ns = vim.api.nvim_create_namespace('')
  local color_used_write = fmt('kk_highlight_%s_write',math.fmod(color_index,#colors) + 1)
  local color_used_read = fmt('kk_highlight_%s_read',math.fmod(color_index,#colors) + 1)
  color_index = color_index + 1
  if reference_mark_group[bufnr]==nil then
    vim.pretty_print(reference_mark_group)
    error("reference_mark_group")
    return
  end
  reference_mark_group[bufnr][ns] = {}

  local crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
  crow = crow - 1 -- reference ranges are (0,0)-indexed for (row,col)

  -- NOTE: reference_mark_group: bufnr -> namespace -> references
  local checked = false
  for _, reference in ipairs(_references) do
    local start_line, start_char = reference['range']['start']['line'], reference['range']['start']['character']
    local end_line, end_char = reference['range']['end']['line'], reference['range']['end']['character']
    local start_idx = get_line_byte_from_position(
      bufnr,
      { line = start_line, character = start_char },
      hl_offset_encoding
    )
    local end_idx = get_line_byte_from_position(bufnr, { line = start_line, character = end_char }, hl_offset_encoding)
    local document_highlight_kind = {
      [protocol.DocumentHighlightKind.Text] = color_used_read, --'LspReferenceText',
      [protocol.DocumentHighlightKind.Read] = color_used_read, --'LspReferenceRead',
      [protocol.DocumentHighlightKind.Write] = color_used_write, --'LspReferenceWrite',
    }
    local kind = reference['kind'] or protocol.DocumentHighlightKind.Text

    if not checked then
      local found_ns,_,ns_marks = M.check_if_any_ns_exists({start_line,start_idx})
      if found_ns and found_ns~=ns and ns_marks then
        print("existing old ns: ",found_ns)
        vim.api.nvim_buf_clear_namespace(bufnr, found_ns, 0, -1)
        for _,mark in ipairs(ns_marks) do
          vim.api.nvim_buf_del_extmark(bufnr,found_ns,mark['start'])
          vim.api.nvim_buf_del_extmark(bufnr,found_ns,mark['end'])
        end
        reference_mark_group[bufnr][found_ns] = nil
        checked = true
      end
    end
    profile_end(bufnr,'request->handle')

    highlight.range(
      bufnr,
      ns,
      document_highlight_kind[kind],
      { start_line, start_idx },
      { end_line, end_idx },
      { priority = vim.highlight.priorities.user + 2 }
    )
    profile_end(bufnr,'highlight')

    local start_mark = vim.api.nvim_buf_set_extmark(bufnr,ns,start_line,start_idx,{})
    local end_mark = vim.api.nvim_buf_set_extmark(bufnr,ns,end_line,end_idx,{})
    table.insert(reference_mark_group[bufnr][ns],{['start']=start_mark,['end']=end_mark})
    -- maintain a namespace and a start_mark and a end_mark (it's only once for each buffer, and created/deleted in this code block)
    local symbol_name = vim.api.nvim_buf_get_text(bufnr,start_line,start_idx,end_line,end_idx,{})[1]
    last_highlight[bufnr] = {['ns']=ns,['start']=start_mark,['end']=end_mark,['name']=symbol_name}
    profile_end(bufnr,"extmark")
  end
  print(fmt("kk_highlight: %s %s",#_references,#_references>1 and "references" or "reference"))
end

local function handle_document_highlight(result, bufnr)
  if not bufnr or type(result) ~= 'table' then 
    echo("highlight request results wrong")
    return 
  end
  table.sort(result, function(a, b)
    return before_by_start(a.range, b.range)
  end)
  curr_references[bufnr] = result
  if cursor_in_references(bufnr) then
    -- do not highlight outdated references, maybe the cursor moved in the process of request
    my_buf_highlight_references(bufnr, result)
  else
    error("Cursor moved out of the range")
  end
end
-- main test

function M.check_if_any_ns_exists(position)
  local bufnr = vim.api.nvim_get_current_buf()
  local mark_group = reference_mark_group[bufnr]
  if mark_group == nil then return nil,nil,nil end

  local crow,ccol = nil,nil
  if position==nil then
    crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
    crow = crow - 1
  else
    crow,ccol = position[1],position[2]
  end

  for ns,marks in pairs(mark_group) do
    local ns_found = false
    local mark_found = nil
    for i,mark in ipairs(marks) do
      local _start = vim.api.nvim_buf_get_extmark_by_id(bufnr,ns,mark['start'],{})
      local _end = vim.api.nvim_buf_get_extmark_by_id(bufnr,ns,mark['end'],{})
      local _range = {
        ['start'] = {
          line = _start[1],
          character = _start[2]
        },
        ['end'] = {
          line = _end[1],
          character = _end[2]
        }
      }
      if point_in_range({row=crow,col=ccol},_range) then
        ns_found = true
        mark_found = mark
        break
      end
    end
    if ns_found then
      return ns,mark_found,marks
    end
  end
  return nil,nil,nil
end

function M.kk_highlight()
  -- no need to use timer, because users wil not call this function very frequently
  profile_start(vim.api.nvim_get_current_buf())
  if illuminate_references and #illuminate_references[vim.api.nvim_get_current_buf()] > 0 then
    print("using cached references:->>")
    handle_document_highlight(illuminate_references[vim.api.nvim_get_current_buf()],vim.api.nvim_get_current_buf())
  else
    print("send request by myself")
    local highlight_params = vim.tbl_deep_extend("force",vim.lsp.util.make_position_params(),{offset_encoding=hl_offset_encoding})
    vim.lsp.buf_request(vim.api.nvim_get_current_buf(), 'textDocument/documentHighlight', highlight_params, function(...)
      if vim.fn.has('nvim-0.5.1') == 1 then
        handle_document_highlight(select(2, ...), select(3, ...).bufnr)
      else
        handle_document_highlight(select(3, ...), select(5, ...))
      end
    end)
  end
end

function M.kk_clear_highlight()
  local bufnr = vim.api.nvim_get_current_buf()
  local mark_group = reference_mark_group[bufnr]

  if mark_group == nil then
    return false
  end

  if vim.v.count1 > 1 then
    local number = 0
    for ns,marks in pairs(mark_group) do
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
      reference_mark_group[bufnr][ns] = nil
      for _,mark in ipairs(marks) do
        vim.api.nvim_buf_del_extmark(bufnr,ns,mark['start'])
        vim.api.nvim_buf_del_extmark(bufnr,ns,mark['end'])
      end
      number = number + 1
    end
    print(fmt("kk_clear_highlight: %s %s",number,number>1 and "symbols" or "symbol"))
    return false
  end

  -- NOTE: following logic only triggered manually or by autocmd
  local found_ns,found_mark,ns_marks = M.check_if_any_ns_exists()
  if found_ns~=nil and found_mark~=nil then
    local _start = vim.api.nvim_buf_get_extmark_by_id(bufnr,found_ns,found_mark['start'],{})
    local _end = vim.api.nvim_buf_get_extmark_by_id(bufnr,found_ns,found_mark['end'],{})

    -- NOTE: create/clone temporary ns and mark for later usage, use the ns and mark in reference_mark_group will not work because the ns is already cleared!
    if last_clear[bufnr] ~= nil then
      vim.api.nvim_buf_del_extmark(bufnr,last_clear[bufnr]['ns'],last_clear[bufnr]['start'])
      vim.api.nvim_buf_del_extmark(bufnr,last_clear[bufnr]['ns'],last_clear[bufnr]['end'])
      vim.api.nvim_buf_clear_namespace(bufnr,last_clear[bufnr]['ns'],0,-1)
    end
    local tmp_ns = vim.api.nvim_create_namespace('tmp')
    local tmp_start = vim.api.nvim_buf_set_extmark(bufnr,tmp_ns,_start[1],_start[2],{})
    local tmp_end = vim.api.nvim_buf_set_extmark(bufnr,tmp_ns,_end[1],_end[2],{})
    local symbol_name = vim.api.nvim_buf_get_text(bufnr,_start[1],_start[2],_end[1],_end[2],{})[1]
    last_clear[bufnr] = vim.deepcopy({['start']=tmp_start,['end']=tmp_end,['ns']=tmp_ns,['name']=symbol_name})
    -- END

    -- clear the highlighting
    vim.api.nvim_buf_clear_namespace(bufnr, found_ns, 0, -1)
    -- clear the extmarks
    local number = 0
    for i,mark in ipairs(ns_marks) do
      vim.api.nvim_buf_del_extmark(bufnr,found_ns,mark['start'])
      vim.api.nvim_buf_del_extmark(bufnr,found_ns,mark['end'])
      number = number + 1
    end
    print(fmt("kk_clear_highlight: %s %s",number,number>1 and "references" or "reference"))
    -- clear references to extmarks
    reference_mark_group[bufnr][found_ns] = nil
    return true
  else
    return false
  end
end

function M.next_highlight(direction)
  local buffer = vim.api.nvim_get_current_buf()
  local crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
  crow = crow - 1
  if last_highlight[buffer] == nil then 
    error("no last_highlight")
    return 
  end
  local last_ns = last_highlight[buffer]['ns']
  if reference_mark_group[buffer][last_ns] == nil then
    error('The highlight has been cleared')
    return
  end
  local locations = {}
  local to_jump = nil
  for _,mark in ipairs(reference_mark_group[buffer][last_ns]) do
    local _start = vim.api.nvim_buf_get_extmark_by_id(buffer,last_ns,mark['start'],{})
    local _end = vim.api.nvim_buf_get_extmark_by_id(buffer,last_ns,mark['end'],{})
    table.insert(locations,{['start']={line=_start[1],character=_start[2]},['end']={line=_end[1],character=_end[2]}})
  end
  table.sort(locations, before_by_start)

  local I,J,step = 1,#locations,1
  if direction=='up' then
    I = #locations
    J = 1
    step = -1
  end

  for i = I,J,step do
    local loc = locations[i]
    local condition
    if direction=="down" then
      condition = (loc['start']['line']>crow) or (loc['start']['line']==crow and loc['start']['character']>ccol)
    else
      condition = (loc['start']['line']<crow) or (loc['start']['line']==crow and loc['start']['character']<ccol)
    end
    if condition then
      to_jump = loc['start']
      break
    end
  end

  if to_jump~=nil then
    vim.cmd("normal! m'")
    vim.api.nvim_win_set_cursor(0,{to_jump.line+1,to_jump.character})
    vim.cmd("normal! zv")
  end
end

M.on_attach = function(_bufnr)
  -- init
  if reference_mark_group[_bufnr] == nil then
    reference_mark_group[_bufnr] = {}
  end
  -- init END

  vim.api.nvim_buf_set_keymap(_bufnr,'n','<leader>,',"",{callback=function ()
    clear_by_autocmd[vim.api.nvim_get_current_buf()] = false
    M.kk_highlight() -- will call M.kk_clear_highlight also
  end})
  vim.api.nvim_buf_set_keymap(_bufnr,'n','<leader>.',"",{callback=function ()
    clear_by_autocmd[vim.api.nvim_get_current_buf()] = false
    M.kk_clear_highlight()
  end})

  vim.api.nvim_buf_set_keymap(_bufnr,'n','<leader>i',"",{callback=function()
    vim.pretty_print('inspect reference_mark_group: ',reference_mark_group[_bufnr])
  end})

  vim.api.nvim_buf_set_keymap(_bufnr,'n','<leader>dn','',{callback=function ()
    M.next_highlight('down')
  end})
  vim.api.nvim_buf_set_keymap(_bufnr,'n','<leader>de','',{callback=function ()
    M.next_highlight('up')
  end})

  vim.api.nvim_create_autocmd({'InsertEnter','TextChanged'},{callback=function ()
    local result = M.kk_clear_highlight()
    if result then
      clear_by_autocmd[_bufnr] = true
    end
  end,group=group,buffer=_bufnr})

  vim.api.nvim_create_autocmd('BufDelete',{callback=function ()
    reference_mark_group[_bufnr] = nil
    clear_by_autocmd[_bufnr] = nil
    last_highlight[_bufnr]= nil
    last_clear[_bufnr]= nil
    curr_references[_bufnr] = nil
  end,group=group,buffer=_bufnr})

  vim.api.nvim_create_autocmd({'InsertLeave'},{callback=function ()
    if clear_by_autocmd[_bufnr] then
      local crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
      crow = crow - 1
      local _start = vim.api.nvim_buf_get_extmark_by_id(_bufnr,last_clear[_bufnr]['ns'],last_clear[_bufnr]['start'],{})
      local _end = vim.api.nvim_buf_get_extmark_by_id(_bufnr,last_clear[_bufnr]['ns'],last_clear[_bufnr]['end'],{})
      local _range = {
        ['start'] = {
          line = _start[1],
          character = _start[2]
        },
        ['end'] = {
          line = _end[1],
          character = _end[2]
        }
      }
      local cword = vim.fn.expand('<cword>')
      if point_in_range({row=crow,col=ccol},_range) then
        if cword==last_clear[_bufnr]['name'] then
          M.kk_highlight()
          print("set_highlight_by_autocmd")
        else
          local msg = fmt("You need rename %s to %s",last_clear[_bufnr]['name'],cword)
          vim.notify('WRN: ' .. msg, vim.lsp.log_levels.WARN)
        end
      end
    end
    clear_by_autocmd[_bufnr] = false
  end,group=group,buffer=_bufnr})
end
return M
