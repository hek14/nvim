local M = {}

local function has_comment(bufnr,line_nr)
  local line = vim.api.nvim_buf_get_lines(bufnr,line_nr-1,line_nr,false)[1]
  local found = vim.fn.match(line,'#')
  if found==nil then
    return nil
  end
  while true do
    local result = vim.fn.match(line,'#',found+1)
    if result~=-1 then
      found = result
    else
      break
    end
  end
  local node = require("contrib.treesitter.python").get_node_for_cursor({line_nr,found})
  if node:type()=='source' then
    return {line:sub(1,found-1),line:sub(found+2)} -- remove the '#' char
  else
    return nil
  end
end

local ts_utils = require("nvim-treesitter.ts_utils")
local ts_parsers = require("nvim-treesitter.parsers")
local ts_queries = require("nvim-treesitter.query")
local update_tree = function(bufnr)
  local filelang = ts_parsers.ft_to_lang(vim.api.nvim_buf_get_option(bufnr, "filetype"))
  local parser = ts_parsers.get_parser(bufnr, filelang)
  return parser:parse()
end

M.suppress_line_diagnostic = function(bufnr,curr_line)
  if bufnr==nil then
    -- local
    bufnr = 0
  end
  if curr_line==nil then
    -- local
    curr_line,_ = unpack(vim.api.nvim_win_get_cursor(0))
    curr_line = curr_line - 1
  end
  local diags = vim.lsp.diagnostic.get_line_diagnostics(bufnr, curr_line, {}, nil)
  if #diags==0 then
    return
  end
  local ignore_str = " # pyright: ignore ["
  for i,diag in ipairs(diags) do
    if diag.source=="Pyright" then
      ignore_str = ignore_str .. tostring(diag.code) .. ', '
    end
  end
  ignore_str = ignore_str:sub(1,#ignore_str-2) .. ']'

  local og_line = vim.api.nvim_buf_get_lines(bufnr,curr_line,curr_line+1,false)[1]
  og_line = og_line:gsub('pyright: ignore %[.*%]','')
  og_line = og_line:gsub('%s*$','')
  local match_result = has_comment(bufnr,curr_line+1)
  if match_result==nil then
    vim.api.nvim_buf_set_lines(bufnr,curr_line,curr_line+1,false,{og_line .. ignore_str})
  else
    local og_statement,og_comment = unpack(match_result)
    vim.api.nvim_buf_set_lines(bufnr,curr_line,curr_line+1,false,{og_statement .. ignore_str .. og_comment})
  end
  vim.cmd[[write]]
  return ignore_str
end

M.do_not_suppress_line_diagnostic = function(bufnr,line)
  bufnr = bufnr and bufnr or vim.api.nvim_get_current_buf()
  line = line and line or vim.api.nvim_win_get_cursor(0)[1]
  local result = has_comment(bufnr,line)
  if result==nil then
    return nil
  else
    local statement,comment = unpack(result)
    local match_start,match_end = comment:find("pyright: ignore %[.*%]")
    if match_start==nil then
      return nil
    else
      local remain = comment:sub(match_end+1)
      vim.api.nvim_buf_set_lines(bufnr,line-1,line,false,{(statement:gsub("%s*$",'')) .. (#remain==0 and "" or " # ") .. remain:gsub('^%s*',''):gsub('%s*$','')})
      vim.cmd[[write]]
      return true
    end
  end
end

M.toggle_line_diagnostic = function()
  if M.do_not_suppress_line_diagnostic()==nil then
    M.suppress_line_diagnostic()
  end
end

return M
