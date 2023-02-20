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
  local bufnr = api.nvim_get_current_buf()
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

function M.get_all_window_buffer_filetype()
    local window_buffer_filetype = {}
    local window_tables = vim.api.nvim_list_wins()

    for _, window_id in ipairs(window_tables) do
        if vim.api.nvim_win_is_valid(window_id) then
            local buffer_id = vim.api.nvim_win_get_buf(window_id)
            table.insert(window_buffer_filetype, {
                window_id = window_id,
                buffer_id = buffer_id,
                buffer_filetype = vim.api.nvim_buf_get_option(buffer_id, "filetype"),
            })
        end
    end

    return window_buffer_filetype
end

function M.scroll_docs_to_up(map)
  return function()
    for _, opts in ipairs(M.get_all_window_buffer_filetype()) do
      if vim.tbl_contains(vim.tbl_values({"lsp-hover","lsp-signature-help"}), opts.buffer_filetype) then
        local window_height = vim.api.nvim_win_get_height(opts.window_id)
        local cursor_line = vim.api.nvim_win_get_cursor(opts.window_id)[1]
        local buffer_total_line = vim.api.nvim_buf_line_count(opts.buffer_id)
        ---@diagnostic disable-next-line: redundant-parameter
        local win_first_line = vim.fn.line("w0", opts.window_id)

        if buffer_total_line <= window_height or cursor_line == 1 then
          vim.api.nvim_echo({ { "Can't scroll up", "MoreMsg" } }, false, {})
          return
        end

        vim.opt.scrolloff = 0

        if cursor_line > win_first_line then
          if win_first_line - 5 > 1 then
            vim.api.nvim_win_set_cursor(opts.window_id, { win_first_line - 5, 0 })
          else
            vim.api.nvim_win_set_cursor(opts.window_id, { 1, 0 })
          end
        elseif cursor_line - 5 < 1 then
          vim.api.nvim_win_set_cursor(opts.window_id, { 1, 0 })
        else
          vim.api.nvim_win_set_cursor(opts.window_id, { cursor_line - 5, 0 })
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
    for _, opts in ipairs(M.get_all_window_buffer_filetype()) do
      if vim.tbl_contains(vim.tbl_values({"lsp-hover","lsp-signature-help"}), opts.buffer_filetype) then
        local window_height = vim.api.nvim_win_get_height(opts.window_id)
        local cursor_line = vim.api.nvim_win_get_cursor(opts.window_id)[1]
        local buffer_total_line = vim.api.nvim_buf_line_count(opts.buffer_id)
        ---@diagnostic disable-next-line: redundant-parameter
        local window_last_line = vim.fn.line("w$", opts.window_id)

        if buffer_total_line <= window_height or cursor_line == buffer_total_line then
          vim.api.nvim_echo({ { "Can't scroll down", "MoreMsg" } }, false, {})
          return
        end

        vim.opt.scrolloff = 0

        if cursor_line < window_last_line then
          if window_last_line + 5 < buffer_total_line then
            vim.api.nvim_win_set_cursor(opts.window_id, { window_last_line + 5, 0 })
          else
            vim.api.nvim_win_set_cursor(opts.window_id, { buffer_total_line, 0 })
          end
        elseif cursor_line + 5 >= buffer_total_line then
          vim.api.nvim_win_set_cursor(opts.window_id, { buffer_total_line, 0 })
        else
          vim.api.nvim_win_set_cursor(opts.window_id, { cursor_line + 5, 0 })
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
