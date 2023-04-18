-- TODO: why we need to manually add runtimepath in 'headless' mode
vim.opt.runtimepath:append(',~/.local/share/nvim/lazy/nvim-treesitter')
local ts_utils = require("nvim-treesitter.ts_utils")
local ts_parsers = require("nvim-treesitter.parsers")
local ts_queries = require("nvim-treesitter.query")
local ts_locals = require('nvim-treesitter.locals')
local get_node_text = vim.treesitter.query.get_node_text
local log = require'core.utils'.log
local fmt = string.format

local M = {}
local icons = {
  ["class-name"] = ' ',
  ["function-name"] = ' ',
  ["method-name"] = ' ',
  ["container-name"] = 'ﮅ ',
  ["tag-name"] = '炙',
  ["condition-name"] = ' ',
}
-- local icons = {
--   ["class-name"] = 'cls: ',
--   ["function-name"] = 'func: ',
--   ["method-name"] = 'method: ',
--   ["container-name"] = 'container: ',
--   ["tag-name"] = 'tag: ',
--   ["condition-name"] = 'condition: ',
-- }
setmetatable(icons,{
  __index = function ()
    return '  '
  end
})


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

function M.get_root_for_position(line, col, root_lang_tree)
  if not root_lang_tree then
    if not ts_parsers.has_parser() then
      return
    end

    root_lang_tree = ts_parsers.get_parser()
  end

  local lang_tree = root_lang_tree:language_for_range { line, col, line, col }

  for _, tree in ipairs(lang_tree:trees()) do
    local root = tree:root()

    if root and vim.treesitter.is_in_node_range(root, line, col) then
      return root, tree, lang_tree
    end
  end

  -- This isn't a likely scenario, since the position must belong to a tree somewhere.
  return nil, nil, lang_tree
end

function M.get_node_at_cursor(buf, cursor_range, ignore_injected_langs)
  local root_lang_tree = ts_parsers.get_parser(buf)
  if not root_lang_tree then
    return
  end

  local root
  if ignore_injected_langs then
    for _, tree in ipairs(root_lang_tree:trees()) do
      local tree_root = tree:root()
      if tree_root and vim.treesitter.is_in_node_range(tree_root, cursor_range[1], cursor_range[2]) then
        root = tree_root
        break
      end
    end
  else
    root = M.get_root_for_position(cursor_range[1], cursor_range[2], root_lang_tree)
  end

  if not root then
    return
  end

  return root:named_descendant_for_range(cursor_range[1], cursor_range[2], cursor_range[1], cursor_range[2])
end

function M.get_scope(bufnr,position)
  -- local node = vim.treesitter.get_node_at_pos(bufnr,position[1],position[2])
  local node = M.get_node_at_cursor(bufnr,position)
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  if ft == 'tex' then
    -- FIX: important fix for latex
    ft = 'latex'
  end
  local node_data = {}
  local nodes = {}
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
      table.insert(nodes, capture_node)
    end
  end

  local gps_query = ts_queries.get_query(ft, "nvimKK")
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


  local flat_nodes = {}
  for _, v in pairs(nodes) do
    if not vim.tbl_islist(v) then
      table.insert(flat_nodes, v)
    else
      vim.list_extend(flat_nodes, v)
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
    flat_nodes = vim.list_slice(flat_nodes,#flat_nodes-depth+1, #flat_nodes)
    table.insert(context, 1, depth_limit_indicator)
  end

  local context_str = table.concat(context, separator)
  return context_str, flat_nodes
end

function M.get_type(bufnr,position)
  -- position : index from zero, table of {row, col}
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  local node = vim.treesitter.get_node({bufnr=bufnr, pos=position})
  if not node then
    return false
  end
  local node_range = {node:range()}
  local parent = get_main_node(node)
  local parent_range = {parent:range()}
  local q = vim.treesitter.query.get(ft,'locals')
  for id, _node, _meta in q:iter_captures(parent, bufnr, parent_range[1],parent_range[3]+1) do
    if q.captures[id]:match("definition") then
      if vim.deep_equal( { _node:range() }, node_range ) then
        return true
      end
    end
  end
  return false
end


function M.goto_last_context(level)
  local start_line = function(node) 
    local row,_,_,_ = node:range()
    return row + 1
  end

  local start_col = function(node) 
    local _,col,_,_ = node:range()
    return col
  end

  level = level and level or vim.v.count1
  local cursor = vim.api.nvim_win_get_cursor(0)
  local _,data = M.get_scope(0,{cursor[1]-1,cursor[2]})
  local index = #data-level+1
  local target = data[index]
  local curr = vim.api.nvim_win_get_cursor(0)
  while target~=nil do
    if start_line(target)<curr[1] then
      break
    elseif start_line(target)==curr[1] and start_col(target)<curr[2] then
      break
    end
    index = index-1
    target = data[index]
  end

  if target == nil then
    return
  end

  vim.cmd("normal! m'")
  vim.api.nvim_win_set_cursor(0,{start_line(target), start_col(target)})
  vim.cmd("normal! zv")
end


return M
