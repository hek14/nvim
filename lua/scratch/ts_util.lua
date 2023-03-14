local M = {}
local log = require'core.utils'.log
local sel = require('scratch.serialize')
local fmt = string.format
-- local icons = {
--   ["class-name"] = ' ',
--   ["function-name"] = ' ',
--   ["method-name"] = ' ',
--   ["container-name"] = 'ﮅ ',
--   ["tag-name"] = '炙',
-- }
local icons = {
  ["class-name"] = 'cls: ',
  ["function-name"] = 'func: ',
  ["method-name"] = 'method: ',
  ["container-name"] = 'container: ',
  ["tag-name"] = 'tag: ',
  ["condition-name"] = 'condition: ',
}
setmetatable(icons,{
  __index = function ()
    return 'obj: '
  end
})

local file_buf_map = {}

-- TODO: why we need to manually add runtimepath in 'headless' mode
vim.opt.runtimepath:append(',~/.local/share/nvim/lazy/nvim-treesitter')
local ts_utils = require("nvim-treesitter.ts_utils")
local ts_parsers = require("nvim-treesitter.parsers")
local ts_queries = require("nvim-treesitter.query")
local ts_locals = require('nvim-treesitter.locals')
local get_node_text = vim.treesitter.query.get_node_text

local uv = vim.loop

local make_pos_key = function(position)
  return fmt('row:%scol:%s',position[1],position[2])
end

local function parse_position_at_buf(position,bufnr)
  local node = vim.treesitter.get_node_at_pos(bufnr,position[1],position[2])
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  local ret = M.get_data(ft,node,bufnr)
  return ret
end


local update_parse_results = function(item)
  assert(file_buf_map[item.file],"file_buf_map has no: " .. item.file)
  assert(file_buf_map[item.file].filetick==item.filetick,"filetick not latest")

  local pos_key = make_pos_key(item.position)
  if file_buf_map[item.file][pos_key] then
    -- log('use the cached results')
    return file_buf_map[item.file][pos_key]
  else
    local ret = parse_position_at_buf(item.position,file_buf_map[item.file].bufnr)
    file_buf_map[item.file][pos_key] = ret
    return ret
  end
end

local get_main_node = function(node)
  local parent = node:parent()
  local root = ts_utils.get_root_for_node(node)
  local start_row = node:start()
  while (parent ~= nil and parent ~= root and parent:start() == start_row) do
    node = parent
    parent = node:parent()
  end
  return node
end

local matched = function (str)
  return string.match(str,'function') or string.match(str,'class') or string.match(str,'method')
end

local function default_transform(capture_name, capture_text)
  return {
    text = capture_text,
    type = capture_name,
    icon = icons[capture_name]
  }
end

function M.get_data(filelang,node,bufnr)
  local node_data = {}
  local function add_node_data(pos, capture_name, capture_node)
    local text = ""
    text = vim.treesitter.query.get_node_text(capture_node, bufnr)
    if text == nil then
      return nil
    end
    text = string.gsub(text, "%s+", ' ')
    local node_text = default_transform(capture_name,text)

    if node_text ~= nil then
      table.insert(node_data, pos, node_text)
    end
  end

  local gps_query = ts_queries.get_query(filelang, "nvimKK")
  while node do
    local iter = gps_query:iter_captures(node, bufnr)
    local capture_ID, capture_node = iter()

    if capture_node == node then -- NOTE: exact match! avoid the larger parent node to do the repeated things
      if gps_query.captures[capture_ID] == "scope-root" then
        while capture_node == node do
          capture_ID, capture_node = iter()
        end
        local capture_name = gps_query.captures[capture_ID]
        add_node_data(1, capture_name, capture_node)

      elseif gps_query.captures[capture_ID] == "scope-root-2" then
        capture_ID, capture_node = iter()
        local capture_name = gps_query.captures[capture_ID]
        add_node_data(1, capture_name, capture_node)

        capture_ID, capture_node = iter()
        capture_name = gps_query.captures[capture_ID]
        add_node_data(2, capture_name, capture_node)

      end
    end

    node = node:parent()
  end

  local data = {}
  for _, v in pairs(node_data) do
    if not vim.tbl_islist(v) then
      table.insert(data, v)
    else
      vim.list_extend(data, v)
    end
  end

  local context = {}
  for _, v in pairs(data) do
    table.insert(context, v.icon..v.text)
  end

  local depth = 5
  local separator = ' > '
  local depth_limit_indicator = ".."

  if #context > depth then
    context = vim.list_slice(context, #context-depth+1, #context)
    table.insert(context, 1, depth_limit_indicator)
  end

  local context_str = table.concat(context, separator)
  return context_str
end


local function my_old_parse_position_at_buf(position,bufnr)
  local parse_str = {
    ['lua'] = [[
    ((function_declaration
    name: (identifier) @definition.function)
    (#set! definition.function.scope "parent"))

    ((function_declaration
    name: (dot_index_expression
    . (_) @definition.associated (identifier) @definition.function))
    (#set! definition.method.scope "parent"))

    ((function_declaration
    name: (method_index_expression
    . (_) @definition.associated (identifier) @definition.method))
    (#set! definition.method.scope "parent"))

    (assignment_statement
    (variable_list
    (identifier) @definition.function)
    (expression_list
    value: (function_definition)))

    (assignment_statement
    (variable_list
    name: (dot_index_expression) @definition.function)
    (expression_list
    value: (function_definition)))
    ]],
  }
  local node = vim.treesitter.get_node_at_pos(bufnr,position[1],position[2])
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  local ret = {}
  local scope = ts_locals.get_scope_tree(node,bufnr)
  if #scope == 0 then
    return nil
  end
  local root = ts_utils.get_root_for_node(scope[1])
  for i,s in ipairs(scope) do
    local srow,scol,erow,ecol = s:range()
    local srow2,scol2,erow2,ecol2 = root:range()
    if srow==srow2 and scol==scol2 and erow==erow2 and ecol==ecol2 then
      break -- NOTE: hit the root
    end
    if s:type()=='for_statement' then
      table.insert(ret,1,{name='for_statement',text='for'})
    else
      local main_node = get_main_node(s)
      local query = vim.treesitter.parse_query(ft,parse_str[ft])
      for id, captures, metadata in query:iter_captures(main_node,bufnr,main_node:start(),main_node:end_()) do
        local name = query.captures[id] -- name of the capture in the query
        if matched(name) then
          local type = captures:type() -- type of the captured node
          local row1, col1, row2, col2 = captures:range() -- range of the capture
          table.insert(ret,1,{name=name,text=get_node_text(captures,bufnr)})
          break -- found the first one and then just break
        end
      end
    end
  end
  return ret
end

local reload_file = function(item)
  assert(vim.loop.fs_stat(item.file),"file not exists")
  vim.api.nvim_command(fmt('noautocmd edit %s',item.file)) -- the edit command will re-use buffer if the file is already opened
  local bufnr = vim.fn.bufnr(item.file) -- will return the existed bufnr if opened before

  -- NOTE: should set the filetype manually for treesitter parse, because we use noautocmd
  vim.api.nvim_buf_set_option(bufnr,'filetype',item.filetype)
  local filelang = ts_parsers.ft_to_lang(item.filetype)
  local parser = ts_parsers.get_parser(bufnr, filelang)
  parser:parse() -- NOTE: very important to attach a parser to this bufnr
  -- log('file reloaded! ',item.file,file_buf_map[item.file])
  file_buf_map[item.file] = {bufnr=bufnr,filetick=item.filetick}
end

local load_file_with_cache = function(input)
  for _,item in ipairs(input) do
    if file_buf_map[item.file] and file_buf_map[item.file].filetick==item.filetick then
    else
      local ok, err = pcall(reload_file,item)
      if not ok then
        -- log('load file err: ',item.file,err)
        file_buf_map[item.file] = {bufnr=-1,filetick=-1,[make_pos_key(item.position)]='error'} -- NOTE: insert invalid bufnr and filetick
        goto continue
      end
    end
    local ok, err = pcall(update_parse_results,item)
    if not ok then
      -- log("cannot parse item",item,err)
      file_buf_map[item.file][make_pos_key(item.position)] = "error"
    end
    ::continue::
  end
end

local handle = function(id,raw_input,event)
  -- received is a table of string, should concat them for unpickle
  local content = ""
  for i,t in ipairs(raw_input) do
    if i==1 and string.match(t,'FINISHED') then
      vim.cmd[[:q!]]
      return
    end
    content = content .. t .. '\n'
  end
  content = string.sub(content,1,#content-1)
  local input = sel.unpickle(content)

  load_file_with_cache(input)
  if id and event=='stdin' then
    vim.fn.chansend(id,sel.pickle(file_buf_map))
  end
end

M.test = function ()
  log = vim.pretty_print
  local input = R('scratch.two_input_t')
  input = sel.pickle(input)
  input = vim.split(input,'\n')
  handle(nil,input,nil)
  log(file_buf_map)
end

M.get_info_under_cursor = function ()
  log = vim.pretty_print
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.fn.expand('%:p')
  local filetick = 0
  local filetype = vim.api.nvim_buf_get_option(buf,'ft')
  local cursor = vim.api.nvim_win_get_cursor(0)
  local input = {{
    file = file,
    filetick = filetick,
    filetype = filetype,
    position = {cursor[1]-1,cursor[2]}
  }}
  input = sel.pickle(input)
  input = vim.split(input,'\n')
  handle(nil,input,nil)
end

M.wait_stdin = function ()
  vim.fn.stdioopen({on_stdin = handle})
end

return M
