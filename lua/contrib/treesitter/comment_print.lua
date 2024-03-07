local M = {}
function M.comment_print_in_current_scope()
  local bufnr = 0
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  local lang = vim.treesitter.language.get_lang(ft)
  if not lang then
    return
  end

  local all_query_strs = {
    lua = [[
(function_call (identifier) @print_function (#match? @print_function "\(print\|printf\)") (#offset! @print_function 1 1 1 1))
(function_call
  name: (dot_index_expression
    table: (identifier) @tbl_name (#eq? @tbl_name "vim") (#offset! @tbl_name 1 1 1 1)
    field: (identifier) @field_name (#eq? @field_name "print") (#offset! @field_name 1 1 1 1)
    ))
    ]]
  }
  setmetatable(all_query_strs, {
    __index = function(_, lang)
      return [[function: ((identifier) @print_function (#match? @print_function "\(print\|printf\)") (#offset! @print_function 1 1 1 1))]]
    end
  })
  local query_str = all_query_strs[lang]

  local comment_char = {
    python= "#",
    cpp= "//",
    lua= "--",
  }

  local cursor = vim.api.nvim_win_get_cursor(0)
  cursor[1] = cursor[1] - 1

  local parser = vim.treesitter.get_parser(bufnr, lang):parse()
  local root = vim.treesitter.get_parser(bufnr, lang):parse()[1]:root()

  local node = vim.treesitter.get_node({bufnr = bufnr, lang = lang, pos = cursor})
  local scopes = {}
  while node do
    if(node:type() == 'function_declaration' or node:type() == 'function_definition' or node:type() == 'class_definition' or node:type() == 'if_statement' or node:type() == 'module') then
      table.insert(scopes, node)
    end
    node = node:parent()
  end

  if(#scopes == 0) then
    vim.print("Error, cannot parse scope!")
  else
    local scope = scopes[1]
    local query = vim.treesitter.query.parse(lang, query_str)
    local iter = query:iter_matches(scope, bufnr)

    local locations = {}
    for pattern, match, metadata in iter do
      -- vim.print({pattern = pattern, match = match, metadata = metadata})
      for id, nodes in pairs(match) do
        local node_data = metadata[id]
        local range = node_data.range
        -- vim.print({pattern = pattern, id = id, range = vim.inspect(range), node_data = node_data, q = query.captures[id]})
        if(query.captures[id] ~= "field_name") then
          table.insert(locations, node_data.range)
        end
      end
    end
    for _, e in ipairs(locations) do
      local line = vim.api.nvim_buf_get_lines(bufnr, e[1]-1, e[1], false)[1]
      local spaces = string.find(line, "%S")
      if(not spaces) then
        goto continue
      end
      spaces = spaces - 1
      local actual_line = string.sub(line, spaces+1, -1)
      local after_line = ""
      for _ = 1,spaces do
        after_line = after_line .. " "
      end
      after_line = after_line .. comment_char[lang] .." ".. actual_line
      vim.api.nvim_buf_set_lines(bufnr, e[1]-1, e[1], false, {after_line})
      -- vim.api.nvim_buf_set_lines(bufnr, e[1]-1, e[1], false, {""})
      ::continue::
    end
  end
end
return M
