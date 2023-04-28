local M = {}
local get_node_for_cursor = function(cursor)
  local ts_utils = require("nvim-treesitter.ts_utils")
  local root = ts_utils.get_root_for_position(unpack({ cursor[1] - 1, cursor[2] }))
  if not root then return end
  return root:named_descendant_for_range(cursor[1] -1 , cursor[2], cursor[1] - 1, cursor[2])
end

local get_main_node = function(cursor)
  local ts_utils = require("nvim-treesitter.ts_utils")
  local node = get_node_for_cursor(cursor)
  if node == nil then
    return nil
  end
  local parent = node:parent()
  local root = ts_utils.get_root_for_node(node)
  local start_row = node:start()
  while (parent ~= nil and parent ~= root and parent:start() == start_row) do
    node = parent
    parent = node:parent()
    -- if vim.tbl_contains({'if_statement' , 'block' , 'while_statement' , 'assignment_statement'},node:type()) then
    --   break
    -- end
  end
  return node
end


M.my_better_substitute = function()
  local ts = vim.treesitter
  local ts_utils = require("nvim-treesitter.ts_utils")
  local buffer = vim.api.nvim_get_current_buf()
  local lang = vim.api.nvim_buf_get_option(buffer,"ft")
  local get_lines = function (line_start,line_end)
    return vim.api.nvim_buf_get_lines(buffer, line_start, line_end, false)
  end
  local win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local current_node = get_node_for_cursor(cursor)
  local parent_node = get_main_node(cursor)
  local parent_start_row,_,parent_end_row,_ = parent_node:range()
  local get_node_text = vim.treesitter.get_node_text
  local query_str = string.format([[((%s) @idname (#eq? @idname "%s"))]],current_node:type(),get_node_text(current_node,buffer))
  query_str = string.sub(query_str,1,#query_str)
  local query = ts.query.parse(lang, query_str)
  local result = ''
  local last_end_col,last_end_row = 0,parent_start_row
  local on_confirm = function(new_name)
    for pattern, match, metadata in query:iter_matches(parent_node, buffer) do
      for id,node in pairs(match) do
        local start_row,start_col,end_row,end_col = node:range()
        if last_end_row == start_row then
          result = result .. string.sub(get_lines(last_end_row,last_end_row+1)[1],last_end_col+1,start_col) .. new_name
        else
          local line = get_lines(last_end_row,last_end_row+1)[1]
          result = result .. string.sub(line,last_end_col+1,#line) .. '\n' -- NOTE: after the last tail
          local lines = get_lines(last_end_row+1,start_row)
          for _,line in ipairs(lines) do
            result = result .. line .. '\n' -- NOTE: the middle lines (whole)
          end
          line = get_lines(start_row,start_row+1)[1]
          result = result .. string.sub(line,1,start_col) .. new_name -- NOTE: before the new start
        end
        last_end_col = end_col
        last_end_row = end_row
      end
    end
    local line = get_lines(last_end_row,last_end_row+1)[1]
    result = result .. string.sub(line,last_end_col+1,#line) .. '\n' -- NOTE: after the final tail
    for _,line in ipairs(get_lines(last_end_row+1,parent_end_row+1)) do
      result = result .. line .. '\n'
    end
    local split = require("core.utils").stringSplit
    result = split(result,'\n')
    result[#result] = nil -- remove the last empty \n line
    -- vim.print(result)
    vim.api.nvim_buf_set_lines(buffer,parent_start_row,parent_end_row+1,false,result)
  end
  vim.ui.input({ prompt = 'replace with: '},on_confirm)
end
return M
