-- what is userdata: they are C values stored in lua
-- how to inspect userdata: vim.print(getmetatable(object))
-- telescope
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

-- treesitter
local my_ts = require('contrib.treesitter')
local ts_utils = require("nvim-treesitter.ts_utils")
local ts_locals = require("nvim-treesitter.locals")
local get_node_text = vim.treesitter.get_node_text
-- luasnip
local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

local M = {}

local get_args = function(argument_string)
  local arguments = require('core.utils').stringSplit(argument_string,',')
  if arguments[1] == "self" then
    arguments = vim.list_slice(arguments,2,#arguments)
  end
  for j = 1,#arguments do
    if string.find(arguments[j],"\n") then
      arguments[j] = string.gsub(arguments[j],"\n","")
    end
    if string.sub(arguments[j],1,1)==" "then
      arguments[j] = string.gsub(arguments[j]," *(.*)","%1")
    end
    if string.find(arguments[j],"=") then
      arguments[j] = string.gsub(arguments[j],"(.-) *= *(.-)","%1 = %2")
    end
  end
  -- P('good arguments: ',arguments)
  return arguments
end

local class_generic_query_string = [[
    (class_definition
      name: (identifier) @cls_name
      body: (block
        (function_definition 
          name: (identifier) @func_name (#match? @func_name "(%s)")
          parameters: (parameters) @params)))
]]

function M.goto_python_main(buffer)
  local buffer = buffer or vim.api.nvim_get_current_buf()
  local query = [[
(if_statement 
  condition: (comparison_operator 
  (identifier) @name (#eq? @name "__name__") (#offset! @name) (#set! @name "hello" "world")
  (string) @main (#match? @main "[\"\']__main__[\"\']")
))
  ]]
  local iter = my_ts.get_query_matches(buffer,'python',query)
  local locations = {}
  for who,match,metadata in iter do
    -- vim.print(metadata)
    table.insert(locations, {
      start = {metadata[1].range[1]+1,metadata[1].range[2]}
    })
  end
  -- actually: a python file should only have one '__name__=="__main__"'
  if #locations>=1 then
    vim.api.nvim_win_set_cursor(0,locations[1].start)
  else
    print("no main block found")
  end
end

M.fast_init_class = function ()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local bufnr = vim.api.nvim_get_current_buf()
  local node = M.go_up_to_class_node(cursor)
  -------------------- first: __init__
  local query = string.format(class_generic_query_string,"__init__")
  local iter = my_ts.get_query_matches(bufnr,'python',query,node)
  local counts = 0
  local class_name = nil
  local init_args = nil
  for _,match,metadata in iter do
    class_name = get_node_text(match[1],bufnr)
    local params = get_node_text(match[3],bufnr)
    local arguments = string.sub(params,2,#params-1)
    init_args = get_args(arguments)
    counts = counts + 1
  end
  for i,_ in ipairs(init_args) do
    if string.find(init_args[i],"=") then
      init_args[i] = string.gsub(init_args[i],"(.-) *=.+","%1")
    end
  end
  local assignment_nodes = fmt([[
{}
{}
  ]],{
      d(1,function(_,_,_,user_args_1)
        local nodes = {}
        for i,arg in ipairs(user_args_1) do
          print(string.format("arg %s: %s",i,arg))
          table.insert(nodes,sn(i,fmt("self.{} = {}",{t(arg),t({arg,i<#user_args_1 and "" or nil})})))
        end
        print("length of nodes: ",#nodes)
        return sn(nil,nodes)
      end,{},{user_args={init_args}}),
      i(0,"continue")
    })
  local assignment_shot = s("kk_assignment",assignment_nodes)
  ls.snip_expand(assignment_shot)
end

M.get_node_for_cursor = function(cursor)
  if cursor == nil then
    cursor = vim.api.nvim_win_get_cursor(0)
  end
  local root = ts_utils.get_root_for_position(unpack({ cursor[1] - 1, cursor[2] }))
  if not root then print('no node at cursor') return end
  return root:named_descendant_for_range(cursor[1] -1 , cursor[2], cursor[1] - 1, cursor[2])
end

M.get_unit_node = function(cursor)
  local node = M.get_node_for_cursor(cursor)
  if node == nil then
    return node
  end
  local parent = node:parent()
  local root = ts_utils.get_root_for_node(node)
  local start_row = node:start()
  while (parent ~= nil and parent ~= root and parent:start() == start_row) do
    node = parent
    parent = node:parent()
  end
  return node
end

M.grep_signature = function(entry)
  --  entry is like: 
  --  {
  --    col = 25,
  --    filename = "/private/tmp/test.lua",
  --    kind = "Constant",
  --    lnum = 39,
  --    text = "[Constant] opts"
  --  }
  if entry.kind == "Class" then
    M.grep_class_signature(entry)
  end
  if entry.kind == "Function" then
    M.grep_function_signature()
  end
end


function M.expand_class_snippet(class_name,init_args,call_args)
  if not class_name then return end
  ------------------ init part
  local init_shot = fmt([[
def test_{}():
    ####### generated by bot kk
{}
    obj_{} = {}({})

]],{
      sn(1,t{class_name}),
      d(2,function (_, _, _, user_args_1)
        vim.print("user_args_1: ",user_args_1)
        local nodes = {}
        for kk,arg in ipairs(user_args_1) do
          if kk < #user_args_1 then 
            if not string.find(arg,'=') then
              table.insert(nodes,sn(kk,fmt("{} = {}{}",{t("    " .. arg),i(1,"arg" .. kk),t{" ",""}})))
            else
              table.insert(nodes,sn(kk,fmt("{}{}{}",{t("    "),i(1,arg),t{" ",""}})))
            end
          else
            if not string.find(arg,'=') then
              table.insert(nodes,sn(kk,fmt("{} = {}",{t("    " .. arg),i(1,"arg" .. kk)})))
            else
              table.insert(nodes,sn(kk,fmt("{}{}",{t("    "),i(1,arg)})))
            end
          end
        end
        return sn(nil,nodes)
      end,{},{user_args = {init_args}}),
      rep(1),
      rep(1),
      f(function(_, _, user_args_1)
        local args = {}
        for j,arg in ipairs(user_args_1) do
          if arg:find("=") then
            local to_sub = string.gsub(arg,"(.-) *=.+","%1")
            table.insert(args,to_sub)
          else
            table.insert(args,arg)
          end
        end
        return table.concat(args,",")
      end, {}, {user_args = {init_args}}),
      -- NOTE: example of using sibling nodes:
      -- f(function(args, _, _)
      --   return '*' .. args[1][1] .. "_init()"
      -- end, {1})
    }) 
  ---------------- call part
  local call_shot = fmt("{}{}",{t("    "),i(1,"do something")})
  if call_args then
    call_shot = fmt([[
{}
    output = {}({})
    print("output: ",{})
test_{}()
      ]],{
        d(1,function (_, _, _, user_args_1)
          local nodes = {}
          for kk,arg in ipairs(user_args_1) do
            if kk < #user_args_1 then 
              if not string.find(arg,'=') then
                table.insert(nodes,sn(kk,fmt("{} = {}{}",{t("    " .. arg),i(1,"arg" .. kk),t{" ",""}})))
              else
                table.insert(nodes,sn(kk,fmt("{}{}{}",{t("    "),i(1,arg),t{" ",""}})))
              end
            else
              if not string.find(arg,'=') then
                table.insert(nodes,sn(kk,fmt("{} = {}",{t("    " .. arg),i(1,"arg" .. kk)})))
              else
                table.insert(nodes,sn(kk,fmt("{}{}",{t("    "),i(1,arg)})))
              end
            end
          end
          return sn(nil,nodes)
        end,{},{user_args={call_args}}),
        f(function(_, _, user_args_1)
          return 'obj_' .. user_args_1
        end,{},{user_args={class_name}}),
        f(function(_, _, user_args_1)
          local args = {} 
          for j,arg in ipairs(user_args_1) do
            if arg:find("=") then
              local to_sub = string.gsub(arg,"(.-) *=.+","%1")
              table.insert(args,to_sub)
            else
              table.insert(args,arg)
            end
          end
          return table.concat(args,",") 
        end, {}, {user_args={call_args}}),
        i(3,"output.shape"),
        f(function(_,_,user_args_1)
          return user_args_1
        end,{},{user_args={class_name}})
      })
  end
  local combine_shots = s("kk_specical",{
    sn(1,init_shot), -- NOTE: the second arguments here for sn is a list of nodes, not a snippet like: s('',{}), only the {} is needed
    sn(2,call_shot),
  })
  ls.snip_expand(combine_shots)
end

vim.treesitter.set_query(
  "python",
  "class_name",
  [[ 
    (class_definition
      name: (identifier) @class_name)
  ]]
)

M.get_class_name = function()
  local cursor_node = ts_utils.get_node_at_cursor()
  local scope = ts_locals.get_scope_tree(cursor_node, 0)
  local class_node
  for _, v in ipairs(scope) do
    if v:type() == "class_definition" then
      class_node = v
      break
    end
  end
  local query = vim.treesitter.get_query("python", "class_name")
  if class_node==nil then
    return nil
  else
    local class_name = nil
    for _, node in query:iter_captures(class_node, 0) do
      class_name = get_node_text(node,0)
    end
    return class_name
  end
end

function M.grep_class_signature(entry)
  local node = M.get_unit_node({entry.lnum,entry.col})
  local bufnr = vim.api.nvim_get_current_buf()
  -------------------- first: __init__
  local query = string.format(class_generic_query_string,"__init__")
  local iter = my_ts.get_query_matches(bufnr,'python',query,node)
  local counts = 0
  local class_name = nil
  local init_args = nil
  local call_args = nil
  for _,match,metadata in iter do
    class_name = get_node_text(match[1],bufnr)
    local params = get_node_text(match[3],bufnr)
    local arguments = string.sub(params,2,#params-1)
    init_args = get_args(arguments)
    counts = counts + 1
  end
  -------------------- second: forward/call
  query = string.format(class_generic_query_string,"forward|__call__")
  iter = my_ts.get_query_matches(bufnr,'python',query,node)
  counts = 0
  for _,match,metadata in iter do
    local params = get_node_text(match[3],bufnr)
    local arguments = string.sub(params,2,#params-1)
    call_args = get_args(arguments)
    counts = counts + 1
  end
  -- if counts > 0 then
  --   print(string.format("class name: %s, args: %s",class_name,vim.inspect(call_args)))
  -- end
  M.expand_class_snippet(class_name,init_args,call_args)
  return class_name,init_args,call_args
end

function M.grep_function_signature()
  return "Not Implemented"
end

function M.go_up_to_class_node(cursor)
  local line = vim.api.nvim_buf_get_lines(0,cursor[1],cursor[1]+1,false)[1]
  while string.match(line,"^%s*$") do
    cursor[1] = cursor[1] - 1
    if cursor[1] < 1 then
      break
    end
    line = vim.api.nvim_buf_get_lines(0,cursor[1],cursor[1]+1,false)[1]
  end
  local node = M.get_node_for_cursor(cursor)
  if node:start() == 0 then
    cursor[1] = cursor[1] - 1
    node = M.get_node_for_cursor(cursor)
  end
  local parent = node:parent()
  local root = ts_utils.get_root_for_node(node)
  local counts = 0
  local found = false
  while (parent ~= nil and parent ~= root) do
    node = parent
    parent = node:parent()
    counts = counts + 1
    if node:type() == "class_definition" then
      found = true
      break
    end
  end
  if found then
    print("found class parent")
    return node
  else
    return nil
  end
end

M.fast_signature = function(opts)
  local opts = opts or {}
  local utils = require "telescope.utils"
  local params = vim.lsp.util.make_position_params(opts.winnr)
  local make_entry = require "telescope.make_entry"
  vim.lsp.buf_request(opts.bufnr, "textDocument/documentSymbol", params, function(err, result, _, _)
    if err then
      vim.api.nvim_err_writeln("Error when finding document symbols: " .. err.message)
      return
    end

    if not result or vim.tbl_isempty(result) then
      print "No results from textDocument/documentSymbol"
      return
    end

    local locations = vim.lsp.util.symbols_to_items(result or {}, opts.bufnr) or {}
    opts.symbols = "class" -- only list the class nodes
    locations = utils.filter_symbols(locations, opts)
    if locations == nil then
      -- error message already printed in `utils.filter_symbols`
      return
    end

    if vim.tbl_isempty(locations) then
      print "locations table empty"
      return
    end

    opts.ignore_filename = opts.ignore_filename or true
    pickers.new(opts, {
      prompt_title = "LSP Document Symbols",
      finder = finders.new_table {
        results = locations,
        entry_maker = opts.entry_maker or make_entry.gen_from_lsp_symbols(opts),
      },
      previewer = conf.qflist_previewer(opts),
      sorter = conf.prefilter_sorter {
        tag = "symbol_type",
        sorter = conf.generic_sorter(opts),
      },
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selected = action_state.get_selected_entry()
          require'contrib.treesitter.python'.grep_signature(selected.value)
        end)
        return true
      end,
    }):find()
  end)
end

return M
