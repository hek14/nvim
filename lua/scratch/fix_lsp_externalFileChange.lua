local ts = vim.treesitter
local ts_utils = require 'nvim-treesitter.ts_utils'
local uv = vim.loop
local fd = require('scratch.fd_exe')

local query = [[
(import_statement
  name: (dotted_name) @kk_modules)
(import_from_statement
  module_name: (dotted_name) @kk_modules)
(import_statement
  name: (aliased_import
          name: (dotted_name) @kk_modules))
]]
local parsed_query = ts.query.parse("python", query)
-- local print = _G.p

local kk_modules = {}

local state = {}
local old_state = {}
local files = {}
function test_get_node()
    local start = vim.loop.hrtime()
    local bufnr = vim.api.nvim_get_current_buf()
    local parser = ts.get_parser(bufnr, "python")
    local root = parser:parse()[1]:root()
    local start_row, _, end_row, _ = root:range()
    local modules = {}
    for id, node in parsed_query:iter_captures(root, bufnr, start_row, end_row) do
      local name = vim.treesitter.get_node_text(node,bufnr)
      name = string.gsub(name,'%.','/')
      table.insert(modules,name)
      fd.find(name .. '.py')
    end
    local try = 0
    while true do
      try = try+1
      if #vim.tbl_keys(fd.files) == #modules then
        print('finished')
      else
        vim.loop.sleep(10)
      end
      if try > 1000 then
        break
      end

    end
    print("spent: ",(vim.loop.hrtime()-start)/1000000,"ms")
    print('try: ',try)
    print(vim.inspect(fd.files))
end

function print_node(title, node,bufnr)
    print(string.format("%s: type '%s' isNamed '%s', text: ", title, node:type(), node:named(), vim.treesitter.get_node_text(node,bufnr)))
end

vim.api.nvim_set_keymap('n', '<leader>z', ':lua test_get_node()<CR>', { noremap = true, silent = false })
