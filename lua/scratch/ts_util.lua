-- refer: https://www.youtube.com/watch?v=86sgKa0jeO4&ab_channel=s1n7ax
-- refer: https://github.com/s1n7ax/youtube-neovim-treesitter-query
-- get language tree: local language_tree = vim.treesitter.get_parser(bufnr)
-- get build syntax tree: local syntax_tree = language_tree:parse()
-- root node of syntax tree: local root = syntax_tree[1]:root()


local M = {}
local sel = require('scratch.serialize')
local a = require "plenary.async"
local vim_ts = vim.treesitter
local ts_utils = require("nvim-treesitter.ts_utils")
local ts_parsers = require("nvim-treesitter.parsers")
local ts_queries = require("nvim-treesitter.query")
local get_node_text = vim.treesitter.query.get_node_text

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

M.parse_file_at_location = function(data)
  data = sel.unpickle(data)
  for i,item in ipairs(data) do
    local bufnr = vim.fn.bufload(item.file)
  end
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
  ]],
}

local matched = function (str)
  return string.match(str,'function') or string.match(str,'class') or string.match(str,'method')
end

local start = uv.hrtime()
local file_buf = {}
read_file('/Users/hk/.config/nvim/test.lua',vim.schedule_wrap(function(data)
  data = vim.split(data,'\n')
  local bufnr = vim.api.nvim_create_buf(true,true) -- TODO: check file_buf to use the cached resolved bufs
  vim.api.nvim_buf_set_option(bufnr,'filetype','lua')
  vim.api.nvim_buf_set_lines(bufnr,0,-1,false,data)
  local parser = update_tree(bufnr)
  vim.schedule(function ()
    local node = vim.treesitter.get_node_at_pos(bufnr,5,16)
    local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
    local ret = {}
    local scope = require('nvim-treesitter.locals').get_scope_tree(node,bufnr)
    for i,s in ipairs(scope) do
      if i == #scope then
        break
      end
      if s:type()=='for_statement' then
        print('just for')
        table.insert(ret,1,'for')
      else
        local main_node = get_main_node(s)
        print('try get main: ',main_node:range())
        -- local query = vim.treesitter.get_query(ft,'locals')
        local query = vim.treesitter.parse_query(ft,parse_str[ft])
        for id, captures, metadata in query:iter_captures(main_node,bufnr,main_node:start(),main_node:end_()) do
          local name = query.captures[id] -- name of the capture in the query
          if matched(name) then
            local type = captures:type() -- type of the captured node
            local row1, col1, row2, col2 = captures:range() -- range of the capture
            print('=======')
            print('range: ',vim.inspect({row1,col1,row2,col2}))
            print('text: ',get_node_text(captures,bufnr))
            table.insert(ret,1,{name=name,text=get_node_text(captures,bufnr)})
            break -- found the first one and then just break
          end
        end
      end
    end
    print('spent: ',(uv.hrtime()-start)/1e6) 
    vim.pretty_print(ret)
    vim.api.nvim_buf_delete(bufnr,{unload=true})
  end)
end))
