-- refer: https://www.youtube.com/watch?v=86sgKa0jeO4&ab_channel=s1n7ax
-- refer: https://github.com/s1n7ax/youtube-neovim-treesitter-query
-- get language tree: local language_tree = vim.treesitter.get_parser(bufnr)
-- get build syntax tree: local syntax_tree = language_tree:parse()
-- root node of syntax tree: local root = syntax_tree[1]:root()


local log = require'core.utils'.log
local sel = require('scratch.serialize')
TEST = false
-- local icons = {
--   ["class-name"] = ' ',
--   ["function-name"] = ' ',
--   ["method-name"] = ' ',
--   ["container-name"] = 'ﮅ ',
--   ["tag-name"] = '炙',
-- }
local icons = {
  ["class-name"] = 'cls:',
  ["function-name"] = 'func:',
  ["method-name"] = 'method:',
  ["container-name"] = 'obj:',
  ["tag-name"] = 'tag:',
}
setmetatable(icons,{
  __index = function ()
    return '🐷'
  end
})


-- TODO: why we need to manually add runtimepath in 'headless' mode
vim.opt.runtimepath:append(',~/.local/share/nvim/lazy/nvim-treesitter')
local ts_utils = require("nvim-treesitter.ts_utils")
local ts_parsers = require("nvim-treesitter.parsers")
local ts_queries = require("nvim-treesitter.query")
local ts_locals = require('nvim-treesitter.locals')
local get_node_text = vim.treesitter.query.get_node_text
log("nvim-treesitter imported")

local uv = vim.loop
local read_file = function(path, callback)
  uv.fs_open(path, "r", 438, function(err, fd)
    assert(not err, err)
    uv.fs_fstat(fd, function(err, stat)
      assert(not err, err)
      uv.fs_read(fd, stat.size, 0, function(err, data)
        assert(not err, err)
        uv.fs_close(fd, function(err)
          assert(not err, err)
          callback(data)
        end)
      end)
    end)
  end)
end

local update_tree = ts_utils.memoize_by_buf_tick(function(bufnr)
  local filelang = ts_parsers.ft_to_lang(vim.api.nvim_buf_get_option(bufnr, "filetype"))
  local parser = ts_parsers.get_parser(bufnr, filelang)
  parser:parse()  -- NOTE: very important to attach a parser to this bufnr
  return parser
end)

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

local function get_data(filelang,node,bufnr)
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

  local gps_query = ts_queries.get_query(filelang, "nvimGPS")
  while node do
    local iter = gps_query:iter_captures(node, bufnr)
    local capture_ID, capture_node = iter()

    if capture_node == node then
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

  context = table.concat(context, separator)
  return context
end


local function my_old_parse_position_at_buf(position,bufnr)
  local node = vim.treesitter.get_node_at_pos(bufnr,position[1],position[2])
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  local ret = {}
  local scope = ts_locals.get_scope_tree(node,bufnr)
  if #scope == 0 then
    return nil
  end
  local root = ts_utils.get_root_for_node(scope[1])
  log('total scope: ',#scope)
  for i,s in ipairs(scope) do
    local srow,scol,erow,ecol = s:range()
    local srow2,scol2,erow2,ecol2 = root:range()
    if srow==srow2 and scol==scol2 and erow==erow2 and ecol==ecol2 then
      log('hit root')
      break -- NOTE: hit the root
    end
    log('current s: ',s:range()) 
    if s:type()=='for_statement' then
      table.insert(ret,1,{name='for_statement',text='for'})
    else
      local main_node = get_main_node(s)
      log('main_code for s:',main_node:range())
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

local function parse_position_at_buf(position,bufnr)
  local node = vim.treesitter.get_node_at_pos(bufnr,position[1],position[2])
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  local ret = get_data(ft,node,bufnr)
  return ret
end

local file_buf_map = {}

local load_file_with_cache = function(input)
  local loaded = {} 
  -- NOTE: the read_file is using async callback function, so we need this table to record loaded files
  for i,item in ipairs(input) do 
    if file_buf_map[item.file] and file_buf_map[item.file].filetick == item.filetick then
      log('already in file_buf_map')
      goto skip
    end
    if not vim.tbl_contains(loaded,item.file) then
      table.insert(loaded,item.file)
      read_file(item.file,vim.schedule_wrap(function(data)
        data = vim.split(data,'\n')
        local bufnr = vim.api.nvim_create_buf(true,true)
        vim.api.nvim_buf_set_option(bufnr,'filetype',item.filetype)
        vim.api.nvim_buf_set_lines(bufnr,0,-1,false,data)
        local filelang = ts_parsers.ft_to_lang(item.filetype)
        local parser = ts_parsers.get_parser(bufnr, filelang)
        parser:parse() -- NOTE: very important to attach a parser to this bufnr
        file_buf_map[item.file] = {bufnr=bufnr,filetick=item.filetick}
      end))
    else
      log('already in the loaded queue')
    end
    ::skip::
  end
end

local sync_load_file = function(input,cb)
  local timer = uv.new_timer() 
  timer:start(0,10, vim.schedule_wrap(function()
    local cnt = 0
    for i,item in ipairs(input) do
      if file_buf_map[item.file] then
        cnt = cnt + 1
      end
    end
    if cnt == #input and timer and not timer:is_closing() then
      timer:stop()
      timer:close()
      cb()
    end
  end))
end

local handle = function(id,input,event)
  -- needed item: { file = '', position = '', filetype = '', filetick = '' } filetick is for cache
  -- received is a table, should concat them for unpickle
  local content = ""
  local quit_after_parse = false
  for i,t in ipairs(input) do
    if string.match(t,'FINISHED') then
      quit_after_parse = true
      t = t:gsub('FINISHED','')
      log('should quit_after_parss!',t)
    end
    content = content .. t .. '\n'
  end
  content = string.sub(content,1,#content-1)
  input = sel.unpickle(content)
  load_file_with_cache(input)
  sync_load_file(input,function()
    local results = {}
    for i,item in ipairs(input) do
      -- NOTE: should be already
      local ret = parse_position_at_buf(item.position,file_buf_map[item.file].bufnr)
      if not results[item.file] then
        results[item.file] = {}
      end
      local pos_key = string.format('row:%scol:%s',item.position[1],item.position[2])
      results[item.file][pos_key] = ret
    end
    log('results: ',results)
    if not TEST then
      vim.fn.chansend(id,sel.pickle(results))
      if quit_after_parse then
        vim.cmd[[:q!]]
      end
    end
  end)
end

local function test()
  local input = {
    {
      file = '/Users/hk/.config/nvim/lua/test.lua',
      filetick = 0,
      filetype = 'lua',
      position = {14,14},
    },
    {
      file = '/Users/hk/server_files/qingdao/test/debug.py',
      filetick = 0,
      filetype = 'python',
      position = {61,15},
    },
  }
  input = sel.pickle(input)
  input = vim.split(input,'\n')
  handle(0,input,nil)
end

if TEST then
  test()
else
  vim.fn.stdioopen({on_stdin = handle})
end
