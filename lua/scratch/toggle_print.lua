local ts_utils = require("nvim-treesitter.ts_utils")
local ts_parsers = require("nvim-treesitter.parsers")
local ts_queries = require("nvim-treesitter.query")
local ts_locals = require('nvim-treesitter.locals')
local get_node_text = vim.treesitter.query.get_node_text
local log = require'core.utils'.log
local fmt = string.format

local print_query_str = [[
(function_call
  name: (identifier)@print (#eq? @print "print"))
]]

local log_query_str = [[
(function_call
  name: (identifier)@log (#eq? @log "log"))
]]

local solve_scope = function ()
  local bufnr = vim.api.nvim_get_current_buf()
  local position = vim.api.nvim_win_get_cursor(0)
  position[1] = position[1] - 1
  return require('scratch.ts_util').get_scope(bufnr,position)[2]
end

local function ask_scope()
  -- TODO: refer to /Users/hk/.config/nvim/lua/scratch/nui_tree_example.lua
  local scopes = solve_scope()  
  local bufnr = vim.api.nvim_get_current_buf()
  local texts = {}
  for i, node in ipairs(scopes) do
    local text = get_node_text(node,bufnr)
    table.insert(texts,text)
  end
end
