local api=vim.api
local ok, ts_locals = pcall(require, "nvim-treesitter.locals")
if not ok then
  error("treesitter not installed")
  return nil
end
local utils = require "nvim-treesitter.utils"
local ts_utils = require 'nvim-treesitter.ts_utils'

local M = {}

-- returns r1 < r2 based on start of range
local function before(r1, r2)
  if r1.start.line < r2.start.line then
    return true
  end
  if r2.start.line < r1.start.line then
    return false
  end
  if r1.start.character < r2.start.character then
    return true
  end
  return false
end


local function goto_adjent_reference_fallback(opt)
  vim.api.nvim_echo({{"builtin keywords"}},true,{})
  vim.cmd [[exe "silent keeppatterns normal! *"]]
end

function M.goto_adjacent_usage(delta)
  local opt = {forward = true}
  if delta < 0 then
    opt.forward = false
  end
  bufnr = api.nvim_get_current_buf()
  local node_at_point = ts_utils.get_node_at_cursor()
  if not node_at_point then
    goto_adjent_reference_fallback(opt)
    return
  end

  local def_node, scope = ts_locals.find_definition(node_at_point, bufnr)
  local usages = ts_locals.find_usages(def_node, scope, bufnr)

  local index = utils.index_of(usages, node_at_point)
  if not index then
    goto_adjent_reference_fallback(opt)
    return
  end

  local target_index = (index + delta + #usages - 1) % #usages + 1
  ts_utils.goto_node(usages[target_index])
end
return M
