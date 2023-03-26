# reference
- refer: https://www.youtube.com/watch?v=86sgKa0jeO4&ab_channel=s1n7ax
- refer: https://github.com/s1n7ax/youtube-neovim-treesitter-query

# tsnode/tstree api
some default module used in the later article:
```lua
local ts_utils = require("nvim-treesitter.ts_utils")
local ts_parsers = require("nvim-treesitter.parsers")
local ts_queries = require("nvim-treesitter.query")
local ts_locals = require('nvim-treesitter.locals')
```
- get language tree: 
  `local language_tree = vim.treesitter.get_parser(bufnr)`
- get build syntax tree: 
  `local syntax_tree = language_tree:parse()`
NOTE: Whenever you need to access the current syntax tree, parse the buffer:  
    tstree = language_tree:parse()
This will return a table of immutable |treesitter-tree| that represent the
*current state* of the buffer. When the plugin wants to access the state after a
(possible) edit it should *call `parse()` again*.
- get root node of syntax tree: 
  `local root = syntax_tree[1]:root()` or 
  using `local root = ts_utils.get_root_for_node(node)`
- get node at pos:
  pos: [line,character], line and character should start at zero!
  `vim.treesitter.get_node_at_pos(bufnr,pos[1],pos[2])`
- get node text,range,type,etc.
  - `vim.treesitter.query.get_node_text(node,bufnr)` NOTE: very important to set the bufnr params, or you'll get `nil`
  - `node:range()`
  - `node:type()`
  - `node:child()`
  - `node:parent()`
  - `node:named_children()`
- get node under current cursor:
  1. method 1:
    ```lua
    local cursor = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())
    local node = vim.treesitter.get_node_at_pos(vim.api.nvim_get_current_buf(),pos[1]-1,pos[2])
    ```
  2. method 2:
    ```lua
    local node = ts_utils.get_node_at_cursor(0)
    ```
# query -- structure-wise regex: find a chunk of code that matches the specified structure
- get a query defined in file
`local gps_query = ts_queries.get_query('python', "nvimGPS")`
this will import the query string from: ~/.config/nvim/after/queries/python/nvimGPS.scm
NOTE: multiple definition of queries are okay, they are `either or` logic.
- parse a query from string
```lua
local parse_str = [[
  ((function_declaration
    name: (identifier) @definition.function)
   (#set! definition.function.scope "parent"))
]]
local query = vim.treesitter.parse_query('python',parse_str)`
```
- what is `Query object`
a TS Query is just like a regex search: `(.*)python(.*)`
the results is nil or a iterable generator
- iterate Query results
```lua
local iter = gps_query:iter_captures(node, bufnr)
local capture_ID, capture_node, metadata = iter()
local capture_name = gps_query.captures[capture_ID]
-- or
for capture_ID, node, metadata in query:iter_captures(tree:root(), bufnr, first, last) do
   local name = query.captures[capture_ID] -- name of the capture in the query
   local type = node:type() -- type of the captured node
   local row1, col1, row2, col2 = node:range() -- range of the capture
end
```
# others
- `vim.treesitter.get_captures_at_pos(bufnr, row, col)` to get the capture information
what is capture???
see `/Users/hk/github/nvim-treesitter/queries/lua/highlights.scm` for example
一个位置可能同时match多个结构(pattern), 而且不同的scm文件会定义自己的patterns,
每一个匹配会给当前位置一个capture(就是@符号后面的name), 比方`@field`, `@variable`
这就是capture

- `require('nvim-treesitter.parsers').ft_to_lang`
