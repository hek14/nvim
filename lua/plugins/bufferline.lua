local M = {
  "akinsho/bufferline.nvim",
  event = 'VimEnter',
  init = function()
    local map = require("core.utils").map
    map("n", {"<TAB>","]b"}, ":BufferLineCycleNext <CR>")
    map("n", {"<S-Tab>","[b"}, ":BufferLineCyclePrev <CR>")
  end,
}


function M.config()
  local map = require("core.utils").map
  bufferline = require"bufferline"
  bufferline.setup {
    options = {
      numbers = "ordinal",
      offsets = { { filetype = "NvimTree", text = "", padding = 1 } },
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
  }

  map('n','<leader>0','<cmd>lua require("bufferline").go_to_buffer(0, true)<cr>')
  map('n','<leader>1','<cmd>lua require("bufferline").go_to_buffer(1, true)<cr>')
  map('n','<leader>2','<cmd>lua require("bufferline").go_to_buffer(2, true)<cr>')
  map('n','<leader>3','<cmd>lua require("bufferline").go_to_buffer(3, true)<cr>')
  map('n','<leader>4','<cmd>lua require("bufferline").go_to_buffer(4, true)<cr>')
  map('n','<leader>5','<cmd>lua require("bufferline").go_to_buffer(5, true)<cr>')
  map('n','<leader>6','<cmd>lua require("bufferline").go_to_buffer(6, true)<cr>')
  map('n','<leader>7','<cmd>lua require("bufferline").go_to_buffer(7, true)<cr>')
  map('n','<leader>8','<cmd>lua require("bufferline").go_to_buffer(8, true)<cr>')
  map('n','<leader>9','<cmd>lua require("bufferline").go_to_buffer(9, true)<cr>')
  map('n','<leader>$','<cmd>lua require("bufferline").go_to_buffer(-1, true)<cr>')
end
return M
