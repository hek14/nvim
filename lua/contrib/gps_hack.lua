local ts_utils = require("nvim-treesitter.ts_utils")
local ts_parsers = require("nvim-treesitter.parsers")
local ts_queries = require("nvim-treesitter.query")

local M = {}

local transform = function(text)
  local found = string.find(text,'-')
  if found then
    local END = found - 1
    return text:sub(1,END)
  else
    return text
  end
end


M.gps_context_parent = function(level_up)
  local level_up = level_up and level_up or vim.v.count1
  local filelang = ts_parsers.ft_to_lang(vim.bo.filetype)
  local gps_query = ts_queries.get_query(filelang, "nvimGPS")
  local data = {}
  local node = ts_utils.get_node_at_cursor()

  local function jump_to_parent_node(pos,capture_name,capture_node)
    local text = ""
    text = vim.treesitter.query.get_node_text(capture_node, 0)
    text = string.gsub(text, "%s+", ' ')

    local start_row, start_col, end_row, end_col = ts_utils.get_node_range(capture_node)
    table.insert(data,pos,{
      type = transform(capture_name),
      text = text,
      range = {start_row+1,start_col}
    })
  end

  while node do
    local iter = gps_query:iter_captures(node, 0)
    local capture_ID, capture_node = iter()

    if capture_node == node then
      if gps_query.captures[capture_ID] == "scope-root" then

        while capture_node == node do
          capture_ID, capture_node = iter()
        end
        local capture_name = gps_query.captures[capture_ID]
        jump_to_parent_node(1,capture_name,capture_node)

      elseif gps_query.captures[capture_ID] == "scope-root-2" then

        capture_ID, capture_node = iter()
        local capture_name = gps_query.captures[capture_ID]
        jump_to_parent_node(1,capture_name,capture_node)

        capture_ID, capture_node = iter()
        capture_name = gps_query.captures[capture_ID]
        jump_to_parent_node(2,capture_name,capture_node)
      end
    end
    node = node:parent()
  end

  local target = data[#data-level_up+1]
  vim.cmd("normal! m'")
  print(string.format("jump to %s: %s", target.type, target.text))
  vim.api.nvim_win_set_cursor(0,target.range)
  vim.cmd("normal! zv")
end

return M
