local M = {
  "akinsho/bufferline.nvim",
  enabled = true,
  -- event = 'VimEnter',
  init = function()
    local map = require("core.utils").map
    map("n", {"<Tab>","]b"}, ":BufferLineCycleNext<CR>")
    map("n", {"<S-Tab>","[b"}, ":BufferLineCyclePrev<CR>")
    map("n", "<leader>wa", ":BufferLineMoveNext<CR>")
    map("n", "<leader>wA", ":BufferLineMovePrev<CR>")
  end,
}


function M.config()
  local map = require("core.utils").map
  require"bufferline".setup({
    options = {
      numbers = "ordinal",
      offsets = { { filetype = "NvimTree", text = "Finder", padding = 1 } },
      buffer_close_icon = "",
      modified_icon = "",
      close_icon = "",
      show_close_icon = true,
      left_trunc_marker = "",
      right_trunc_marker = "",
      max_name_length = 14,
      max_prefix_length = 13,
      tab_size = 20,
      show_tab_indicators = true,
      enforce_regular_tabs = false,
      view = "multiwindow",
      show_buffer_close_icons = true,
      separator_style = "thin",
      always_show_bufferline = true,
      diagnostics = false, -- "or nvim_lsp"
      name_formatter = function(buf)  
        return string.format("%s(%d)",buf.name,buf.bufnr)
        -- buf contains:
        -- name                | str        | the basename of the active file
        -- path                | str        | the full path of the active file
        -- bufnr (buffer only) | int        | the number of the active buffer
        -- buffers (tabs only) | table(int) | the numbers of the buffers in the tab
        -- tabnr (tabs only)   | int        | the "handle" of the tab, can be converted to its ordinal number using: `vim.api.nvim_tabpage_get_number(buf.tabnr)`
      end,
      custom_filter = function(buf_number)
        -- Func to filter out our managed/persistent split terms
        local present_type, type = pcall(function()
          return vim.api.nvim_buf_get_var(buf_number, "term_type")
        end)

        if present_type then
          if type == "vert" then
            return false
          elseif type == "hori" then
            return false
          else
            return true
          end
        else
          return true
        end
      end,
    },
    highlights = {
      buffer_selected = {
        fg = '#42fcd4',
        bg = '#616161',
        bold = false,
        italic = false,
      },
      numbers_selected = {
        fg = '#42fcd4',
        bg = '#616161',
        bold = false,
        italic = false,
      },
      close_button_selected = {
        fg = '#FFC0CB',
        bg = '#616161',
      },
      indicator_selected = { -- NOTE: don't work because the theme override the indicator color, should override after setup
        fg = '#FFC0CB',
      },
      modified_selected = {
        fg = '#FFC0CB',
      },
    };
  })
  vim.cmd[[hi! BufferLineIndicatorSelected guifg='#FFC0CB']]

  map('n','<leader>0','<cmd>lua require("bufferline").go_to_buffer(-1, true)<cr>')
  map('n','<leader>1','<cmd>lua require("bufferline").go_to_buffer(1, true)<cr>')
  map('n','<leader>2','<cmd>lua require("bufferline").go_to_buffer(2, true)<cr>')
  map('n','<leader>3','<cmd>lua require("bufferline").go_to_buffer(3, true)<cr>')
  map('n','<leader>4','<cmd>lua require("bufferline").go_to_buffer(4, true)<cr>')
  map('n','<leader>5','<cmd>lua require("bufferline").go_to_buffer(5, true)<cr>')
  map('n','<leader>6','<cmd>lua require("bufferline").go_to_buffer(6, true)<cr>')
  map('n','<leader>7','<cmd>lua require("bufferline").go_to_buffer(7, true)<cr>')
  map('n','<leader>8','<cmd>lua require("bufferline").go_to_buffer(8, true)<cr>')
  map('n','<leader>9','<cmd>lua require("bufferline").go_to_buffer(9, true)<cr>')
end
return M
