local M = {
  "lewis6991/gitsigns.nvim",
  event = 'BufRead',
}

function M.config()
  require"gitsigns".setup {
    signs = {
      add = { hl = "DiffAdd", text = "│", numhl = "GitSignsAddNr" },
      change = { hl = "DiffChange", text = "│", numhl = "GitSignsChangeNr" },
      delete = { hl = "DiffDelete", text = "", numhl = "GitSignsDeleteNr" },
      topdelete = { hl = "DiffDelete", text = "‾", numhl = "GitSignsDeleteNr" },
      changedelete = { hl = "DiffChangeDelete", text = "~", numhl = "GitSignsChangeNr" },
    },
    on_attach = function(bufnr)
      -- if vim.api.nvim_buf_get_name(bufnr):match(<PATTERN>) then
      --   -- Don't attach to specific buffers whose name matches a pattern
      --   return false
      -- end
      require('core.utils').map('n', '<leader>hs', '<cmd>Gitsigns stage_hunk<CR>', {buffer=bufnr})
      require('core.utils').map('n', '<leader>hu', '<cmd>Gitsigns undo_stage_hunk<CR>',{buffer=bufnr})
      require('core.utils').map('n', '<leader>hr', '<cmd>Gitsigns reset_hunk<CR>',{buffer=bufnr})
      require('core.utils').map('n', '<leader>hb', '<cmd>lua require"gitsigns".blame_line{full=true}<CR>',{buffer=bufnr})
      require('core.utils').map('n', '<leader>hp', '<cmd>Gitsigns preview_hunk<CR>',{buffer=bufnr})
      vim.cmd("nnoremap <expr> <buffer> ]c &diff ? ']c' : ':Gitsigns next_hunk<CR>'")
      vim.cmd("nnoremap <expr> <buffer> [c &diff ? '[c' : ':Gitsigns prev_hunk<CR>'")
      require('core.utils').map('x', 'uh','<Cmd>Gitsigns select_hunk<CR>',{buffer=bufnr})
      require('core.utils').map('o', 'uh','<Cmd>Gitsigns select_hunk<CR>',{buffer=bufnr})
    end
  }
end
return M
