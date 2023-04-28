-- NOTE: main steps to develop treesitter:
-- 1. function get current context/node
-- 2. custom query(like structure-level regex)
-- 3. parse capture
local api = vim.api
local ts = vim.treesitter

local M = {}

--[[
-- Returns a iterator for all the matches from the query
-- @returns iterator of all the matches
--]]
function M.get_query_matches(buffer, lang, query_str, root)
    buffer = buffer or api.nvim_get_current_buf()

    local root = root or ts.get_parser(buffer, lang):parse()[1]:root()

    local query = ts.query.parse(lang, query_str)

    return query:iter_matches(root, buffer)
end


-- [[
-- example to iter matches
local extract_all_comments = function(bufnr,line,pattern)
  if bufnr==nil then
    bufnr = vim.fn.bufnr()
  end
  if line==nil then
    line,_ = unpack(vim.api.nvim_win_get_cursor(0))
    line = line - 1
  end
  local lang = vim.api.nvim_buf_get_option(bufnr,'filetype')
  local query = vim.treesitter.query.parse(
  lang,string.format(
  [[
  [
  (comment) @cmt (#contains? @cmt "%s")
  ]
  ]]
  ,pattern))
  local parser = vim.treesitter.get_parser(bufnr, lang)
  local root = parser:parse()[1]:root()
  for id, node, md in query:iter_captures(root, bufnr, 0, -1) do
    local comment = vim.treesitter.get_node_text(node, bufnr)
    print("found comment: ",comment, "at: ",node:range())
  end
end
-- ]]

return M
