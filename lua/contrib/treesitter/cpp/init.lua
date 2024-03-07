local my_ts = require('contrib.treesitter')
local ts_utils = require("nvim-treesitter.ts_utils")
local ts_locals = require("nvim-treesitter.locals")
local get_node_text = vim.treesitter.get_node_text
-- luasnip
local M = {}

function M.goto_main(buffer)
  buffer = buffer or vim.api.nvim_get_current_buf()
  local query = [[
(function_definition
  type: (primitive_type)
  declarator: (function_declarator
    declarator: (identifier) @name (#eq? @name "main") (#offset! @name)
    parameters: (parameter_list))
  body: (compound_statement
    (return_statement
      (number_literal))))
  ]]
  local iter = my_ts.get_query_matches(buffer,'cpp',query)
  local locations = {}
  for who,match,metadata in iter do
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

return M
