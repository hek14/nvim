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
    keymaps = {
      noremap = true,
      ['n <leader>hs'] = '<cmd>Gitsigns stage_hunk<CR>',
      ['v <leader>hs'] = ':Gitsigns stage_hunk<CR>',
      ['n <leader>hu'] = '<cmd>Gitsigns undo_stage_hunk<CR>',
      ['n <leader>hr'] = '<cmd>Gitsigns reset_hunk<CR>',
      ['v <leader>hr'] = ':Gitsigns reset_hunk<CR>',
      ['n <leader>hb'] = '<cmd>lua require"gitsigns".blame_line{full=true}<CR>',
      ['n <leader>hd'] = '<cmd>Gitsigns preview_hunk<CR>',

      ['n ]c'] = { expr = true, "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'"},
      ['n [c'] = { expr = true, "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'"},
      ['o uh'] = ':<C-U>Gitsigns select_hunk<CR>',
      ['x uh'] = ':<C-U>Gitsigns select_hunk<CR>',
    }
  }
end
return M
