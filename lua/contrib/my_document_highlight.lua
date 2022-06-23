local uv = vim.loop
local protocol = require('vim.lsp.protocol')
local highlight = require('vim.highlight')
local fmt = string.format

-- ========== state
local M = {}
local references = {}
local timers = {}
local reference_mark_group = {}
local last_clear_range = {}
local last_highlight_range = {}
local clear_by_autocmd = {}
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

local function my_buf_highlight_references(bufnr, _references, offset_encoding, compare)
  M.kk_clear_highlight()
  local ns = vim.api.nvim_create_namespace('')
  local color_used_write = fmt('kk_highlight_%s_write',math.fmod(color_index,#colors) + 1)
  local color_used_read = fmt('kk_highlight_%s_read',math.fmod(color_index,#colors) + 1)
  color_index = color_index + 1
  if reference_mark_group[bufnr] == nil then
    print('bad, no attach')
    reference_mark_group[bufnr] = {}
  end

  reference_mark_group[bufnr][ns] = {}

  local crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
  crow = crow - 1 -- reference ranges are (0,0)-indexed for (row,col)

  -- NOTE: reference_mark_group: bufnr -> namespace -> references
  for _, reference in ipairs(_references) do
    local start_line, start_char = reference['range']['start']['line'], reference['range']['start']['character']
    local end_line, end_char = reference['range']['end']['line'], reference['range']['end']['character']

    local start_idx = get_line_byte_from_position(
      bufnr,
      { line = start_line, character = start_char },
      offset_encoding
    )
    local end_idx = get_line_byte_from_position(bufnr, { line = start_line, character = end_char }, offset_encoding)

    local document_highlight_kind = {
      [protocol.DocumentHighlightKind.Text] = color_used_read, --'LspReferenceText',
      [protocol.DocumentHighlightKind.Read] = color_used_read, --'LspReferenceRead',
      [protocol.DocumentHighlightKind.Write] = color_used_write, --'LspReferenceWrite',
    }
    local kind = reference['kind'] or protocol.DocumentHighlightKind.Text
    highlight.range(
      bufnr,
      ns,
      document_highlight_kind[kind],
      { start_line, start_idx },
      { end_line, end_idx },
      { priority = vim.highlight.priorities.user + 2 }
    )
    local start_mark = vim.api.nvim_buf_set_extmark(bufnr,ns,start_line,start_idx,{})
    local end_mark = vim.api.nvim_buf_set_extmark(bufnr,ns,end_line,end_idx,{})
    table.insert(reference_mark_group[bufnr][ns],{['start']=start_mark,['end']=end_mark})
    if point_in_range({row=crow,col=ccol}, reference.range) then
      -- maintain a namespace and a start_mark and a end_mark (it's only once for each buffer, and created/deleted in this code block)
      if last_highlight_range[bufnr] ~= nil then
        vim.api.nvim_buf_del_extmark(bufnr,last_highlight_range[bufnr]['ns'],last_highlight_range[bufnr]['start'])
        vim.api.nvim_buf_del_extmark(bufnr,last_highlight_range[bufnr]['ns'],last_highlight_range[bufnr]['end'])
        vim.api.nvim_buf_clear_namespace(bufnr,last_highlight_range[bufnr]['ns'],0,-1)
      end
      local tmp_ns = vim.api.nvim_create_namespace('last_highlight_ns')
      local tmp_start = vim.api.nvim_buf_set_extmark(bufnr,tmp_ns,start_line,start_idx,{})
      local tmp_end = vim.api.nvim_buf_set_extmark(bufnr,tmp_ns,end_line,end_idx,{})
      last_highlight_range[bufnr] = {['ns']=tmp_ns,['start']=tmp_start,['end']=tmp_end}
    end
  end
  print(fmt("kk_highlight: %s %s",#_references,#_references>1 and "references" or "reference"))
end


local function cursor_in_references(bufnr)
  -- do not highlight outdated references
  if not references[bufnr] then
    return false
  end
  if vim.api.nvim_win_get_buf(0) ~= bufnr then
    return false
  end
  local crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
  crow = crow - 1 -- reference ranges are (0,0)-indexed for (row,col)
  for _, reference in pairs(references[bufnr]) do
    local range = reference.range
    if point_in_range({row=crow,col=ccol}, range) then
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

local function handle_document_highlight(result, bufnr, compare)
  if not bufnr then return end
  local btimer = timers[bufnr]
  if btimer then
    vim.loop.timer_stop(btimer) -- avoid high-frequency trigger
  end
  if type(result) ~= 'table' then
    return
  end
  timers[bufnr] = vim.defer_fn(function()
    if cursor_in_references(bufnr) then
      my_buf_highlight_references(bufnr, result, hl_offset_encoding, compare)
    end
    end, 17)
  table.sort(result, function(a, b)
    return before_by_start(a.range, b.range)
  end)
  references[bufnr] = result
end

-- main test
function M.kk_highlight(compare)
  local highlight_params = vim.tbl_deep_extend("force",vim.lsp.util.make_position_params(),{offset_encoding=hl_offset_encoding})
  vim.lsp.buf_request(vim.fn.bufnr(), 'textDocument/documentHighlight', highlight_params, function(...)
    if vim.fn.has('nvim-0.5.1') == 1 then
      handle_document_highlight(select(2, ...), select(3, ...).bufnr, compare)
    else
      handle_document_highlight(select(3, ...), select(5, ...), compare)
    end
  end)
end

function M.check_if_any_ns_exists()
  local bufnr = vim.fn.bufnr()
  local mark_group = reference_mark_group[bufnr]
  if mark_group == nil then return nil,nil,nil end

  local crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
  crow = crow - 1

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

function M.kk_clear_highlight()
  local bufnr = vim.fn.bufnr()
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
  if found_ns then
    local _start = vim.api.nvim_buf_get_extmark_by_id(bufnr,found_ns,found_mark['start'],{})
    local _end = vim.api.nvim_buf_get_extmark_by_id(bufnr,found_ns,found_mark['end'],{})

    -- create temporary ns and mark
    if last_clear_range[bufnr] ~= nil then
      vim.api.nvim_buf_del_extmark(bufnr,last_clear_range[bufnr]['ns'],last_clear_range[bufnr]['start'])
      vim.api.nvim_buf_del_extmark(bufnr,last_clear_range[bufnr]['ns'],last_clear_range[bufnr]['end'])
      vim.api.nvim_buf_clear_namespace(bufnr,last_clear_range[bufnr]['ns'],0,-1)
    end
    local tmp_ns = vim.api.nvim_create_namespace('tmp')
    local tmp_start = vim.api.nvim_buf_set_extmark(bufnr,tmp_ns,_start[1],_start[2],{})
    local tmp_end = vim.api.nvim_buf_set_extmark(bufnr,tmp_ns,_end[1],_end[2],{})
    last_clear_range[bufnr] = vim.deepcopy({['start']=tmp_start,['end']=tmp_end,['ns']=tmp_ns})
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

M.on_attach = function(_bufnr,create_autocmd)
  -- init
  if reference_mark_group[_bufnr] == nil then
    reference_mark_group[_bufnr] = {}
  end
  -- init END

  vim.api.nvim_buf_set_keymap(_bufnr,'n','<leader>,',"",{callback=function ()
    clear_by_autocmd[vim.fn.bufnr()] = false
    M.kk_highlight() -- will call M.kk_clear_highlight also
  end})
  vim.api.nvim_buf_set_keymap(_bufnr,'n','<leader>.',"",{callback=function ()
    clear_by_autocmd[vim.fn.bufnr()] = false
    M.kk_clear_highlight()
  end})

  vim.api.nvim_buf_set_keymap(_bufnr,'n','<leader>i',"",{callback=function()
    local bufnr = vim.fn.bufnr()
    vim.pretty_print('inspect ns number: ',vim.tbl_keys(reference_mark_group[bufnr]))
    if last_clear_range[bufnr]~=nil then
      local _start = vim.api.nvim_buf_get_extmark_by_id(bufnr,last_clear_range[bufnr]['ns'],last_clear_range[bufnr]['start'],{})
      local _end = vim.api.nvim_buf_get_extmark_by_id(bufnr,last_clear_range[bufnr]['ns'],last_clear_range[bufnr]['end'],{})
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
      vim.pretty_print('inspect last_clear_range: ',_range)
    end
    if last_highlight_range[bufnr]~=nil then
      local _start = vim.api.nvim_buf_get_extmark_by_id(bufnr,last_highlight_range[bufnr]['ns'],last_highlight_range[bufnr]['start'],{})
      local _end = vim.api.nvim_buf_get_extmark_by_id(bufnr,last_highlight_range[bufnr]['ns'],last_highlight_range[bufnr]['end'],{})
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
      vim.pretty_print('inspect last_highlight_range: ',_range)
    end
  end})

  local group = vim.api.nvim_create_augroup('kk_highlight',{clear=true})
  vim.api.nvim_create_autocmd({'InsertEnter','TextChanged'},{callback=function ()
    local result = M.kk_clear_highlight()
    if result then
      clear_by_autocmd[vim.fn.bufnr()] = true
    end
  end,group=group})

  vim.api.nvim_create_autocmd('BufDelete',{callback=function ()
    local bufnr = vim.fn.bufnr()
    reference_mark_group[bufnr] = nil
    clear_by_autocmd[bufnr] = nil
    last_highlight_range[bufnr]= nil
    last_clear_range[bufnr]= nil
    references[bufnr] = nil
    timers[bufnr] = nil
  end})

  vim.api.nvim_create_autocmd({'InsertLeave'},{callback=function ()
    local bufnr = vim.fn.bufnr()
    if clear_by_autocmd[bufnr] then
      local crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
      crow = crow - 1
      local _start = vim.api.nvim_buf_get_extmark_by_id(bufnr,last_clear_range[bufnr]['ns'],last_clear_range[bufnr]['start'],{})
      local _end = vim.api.nvim_buf_get_extmark_by_id(bufnr,last_clear_range[bufnr]['ns'],last_clear_range[bufnr]['end'],{})
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
        M.kk_highlight(true)
        print("set_highlight_by_autocmd")
      end
    end
    clear_by_autocmd[bufnr] = false
  end,group=group})
end
return M
