local patterns = {
  ['python'] = '^ *#####',
  ['lua'] = '^ *-----',
  ['zsh'] = '^ *####'
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

  if vim.tbl_isempty(lines_with_numbers) then 
    print('no sections')
    return
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
          vim.schedule(function()
            vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
            vim.cmd [[normal! ^]]
          end)
        end,
      }

      return true
    end,
    push_cursor_on_edit = true,
  })
  :find()
end
return M
