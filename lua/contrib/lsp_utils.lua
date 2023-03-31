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

local index_of = function (t,v)
  local found
  for i, elem in ipairs(t) do
    if vim.deep_equal(elem, v) then
      found = i
      break
    end
  end
  return found
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
  local bufnr = api.nvim_get_current_buf()
  local node_at_point = ts_utils.get_node_at_cursor()
  if not node_at_point then
    goto_adjent_reference_fallback(opt)
    return
  end

  local def_node, scope = ts_locals.find_definition(node_at_point, bufnr)
  local usages = ts_locals.find_usages(def_node, scope, bufnr)

  local index = index_of(usages, node_at_point)
  if not index then
    goto_adjent_reference_fallback(opt)
    return
  end

  local target_index = (index + delta + #usages - 1) % #usages + 1
  ts_utils.goto_node(usages[target_index])
end

function M.scroll_docs_to_up(map)
  return function()
    for _, opts in ipairs(require('core.utils').get_all_window_buffer_filetype()) do
      if vim.tbl_contains(vim.tbl_values({"lsp-hover","lsp-signature-help"}), opts.filetype) then
        local window_height = vim.api.nvim_win_get_height(opts.winnr)
        local cursor_line = vim.api.nvim_win_get_cursor(opts.winnr)[1]
        local buffer_total_line = vim.api.nvim_buf_line_count(opts.bufnr)
        ---@diagnostic disable-next-line: redundant-parameter
        local win_first_line = vim.fn.line("w0", opts.winnr)

        if buffer_total_line <= window_height or cursor_line == 1 then
          vim.api.nvim_echo({ { "Can't scroll up", "MoreMsg" } }, false, {})
          return
        end

        vim.opt.scrolloff = 0

        if cursor_line > win_first_line then
          if win_first_line - 5 > 1 then
            vim.api.nvim_win_set_cursor(opts.winnr, { win_first_line - 5, 0 })
          else
            vim.api.nvim_win_set_cursor(opts.winnr, { 1, 0 })
          end
        elseif cursor_line - 5 < 1 then
          vim.api.nvim_win_set_cursor(opts.winnr, { 1, 0 })
        else
          vim.api.nvim_win_set_cursor(opts.winnr, { cursor_line - 5, 0 })
        end

        vim.opt.scrolloff = 21

        return
      end
    end

    local key = vim.api.nvim_replace_termcodes(map, true, false, true)
    ---@diagnostic disable-next-line: param-type-mismatch
    vim.api.nvim_feedkeys(key, "n", true)
  end
end

function M.scroll_docs_to_down(map)
  return function()
    for _, opts in ipairs(require('core.utils').get_all_window_buffer_filetype()) do
      if vim.tbl_contains(vim.tbl_values({"lsp-hover","lsp-signature-help"}), opts.filetype) then
        local window_height = vim.api.nvim_win_get_height(opts.winnr)
        local cursor_line = vim.api.nvim_win_get_cursor(opts.winnr)[1]
        local buffer_total_line = vim.api.nvim_buf_line_count(opts.bufnr)
        ---@diagnostic disable-next-line: redundant-parameter
        local window_last_line = vim.fn.line("w$", opts.winnr)

        if buffer_total_line <= window_height or cursor_line == buffer_total_line then
          vim.api.nvim_echo({ { "Can't scroll down", "MoreMsg" } }, false, {})
          return
        end

        vim.opt.scrolloff = 0

        if cursor_line < window_last_line then
          if window_last_line + 5 < buffer_total_line then
            vim.api.nvim_win_set_cursor(opts.winnr, { window_last_line + 5, 0 })
          else
            vim.api.nvim_win_set_cursor(opts.winnr, { buffer_total_line, 0 })
          end
        elseif cursor_line + 5 >= buffer_total_line then
          vim.api.nvim_win_set_cursor(opts.winnr, { buffer_total_line, 0 })
        else
          vim.api.nvim_win_set_cursor(opts.winnr, { cursor_line + 5, 0 })
        end

        vim.opt.scrolloff = 21

        return
      end
    end

    local key = vim.api.nvim_replace_termcodes(map, true, false, true)
    ---@diagnostic disable-next-line: param-type-mismatch
    vim.api.nvim_feedkeys(key, "n", true)
  end
end

return M
