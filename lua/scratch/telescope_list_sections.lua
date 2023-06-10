local patterns = {
  ['python'] = '^ *#####',
  ['lua'] = '^ *-----'
}
local M = {}
function M.list_section()
  local action_state = require "telescope.actions.state"
  local action_set = require "telescope.actions.set"
  local actions = require "telescope.actions"
  local finders = require "telescope.finders"
  local make_entry = require "telescope.make_entry"
  local pickers = require "telescope.pickers"
  local previewers = require "telescope.previewers"
  local sorters = require "telescope.sorters"
  local utils = require "telescope.utils"
  local conf = require("telescope.config").values
  local bufnr = vim.api.nvim_get_current_buf()
  local opts = {bufnr=bufnr}
  -- All actions are on the current buffer
  local filename = vim.fn.expand(vim.api.nvim_buf_get_name(opts.bufnr))
  local filetype = vim.api.nvim_buf_get_option(opts.bufnr, "filetype")
  local all_lines = vim.api.nvim_buf_get_lines(opts.bufnr,0,-1,false)
  local lines_with_numbers = {}
  for i,line in ipairs(all_lines) do
    if #vim.fn.matchstr(line,patterns[filetype])>0 then
      local after_line = all_lines[i+1]
      local comment = after_line:gsub(' *# *','')
      table.insert(lines_with_numbers,{
        lnum = i+1,
        bufnr = opts.bufnr,
        filename = filename,
        text = #comment > 0 and comment or "anonymous section",
      })
    end
  end

  vim.print("lines_with_numbers: ",lines_with_numbers)
  if vim.tbl_isempty(lines_with_numbers) then 
    print('no sections')
    return
  end

  local ts_ok, ts_parsers = pcall(require, "nvim-treesitter.parsers")
  if ts_ok then
    filetype = ts_parsers.ft_to_lang(filetype)
  end
  local _, ts_configs = pcall(require, "nvim-treesitter.configs")

  local parser_ok, parser = pcall(vim.treesitter.get_parser, opts.bufnr, filetype)
  local query_ok, query = pcall(vim.treesitter.get_query, filetype, "highlights")
  if parser_ok and query_ok and ts_ok and ts_configs.is_enabled("highlight", filetype, opts.bufnr) then
    local root = parser:parse()[1]:root()

    local line_highlights = setmetatable({}, {
      __index = function(t, k)
        local obj = {}
        rawset(t, k, obj)
        return obj
      end,
    })

    -- update to changes on Neovim master, see https://github.com/neovim/neovim/pull/19931
    -- TODO(clason): remove when dropping support for Neovim 0.7
    local get_hl_from_capture = (function()
      if vim.fn.has "nvim-0.8" == 1 then
        return function(q, id)
          return "@" .. q.captures[id]
        end
      else
        local highlighter = vim.treesitter.highlighter.new(parser)
        local highlighter_query = highlighter:get_query(filetype)

        return function(_, id)
          return highlighter_query:_get_hl_from_capture(id)
        end
      end
    end)()

    for id, node in query:iter_captures(root, opts.bufnr, 0, -1) do
      local hl = get_hl_from_capture(query, id)
      if hl and type(hl) ~= "number" then
        local row1, col1, row2, col2 = node:range()

        if row1 == row2 then
          local row = row1 + 1

          for index = col1, col2 do
            line_highlights[row][index] = hl
          end
        else
          local row = row1 + 1
          for index = col1, #lines_with_numbers[row] do
            line_highlights[row][index] = hl
          end

          while row < row2 + 1 do
            row = row + 1

            for index = 0, #(lines_with_numbers[row] or {}) do
              line_highlights[row][index] = hl
            end
          end
        end
      end
    end
    opts.line_highlights = line_highlights
  end

  pickers
  .new(opts, {
    prompt_title = "Sections",
    finder = finders.new_table {
      results = lines_with_numbers,
      entry_maker = make_entry.gen_from_buffer_lines(opts),
    },
    sorter = conf.generic_sorter(opts),
    previewer = conf.grep_previewer(opts),
    attach_mappings = function()
      action_set.select:enhance {
        post = function()
          local selection = action_state.get_selected_entry()
          vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
        end,
      }

      return true
    end,
    push_cursor_on_edit = true,
  })
  :find()
end
return M
