if vim.g.neovide then
  vim.g.neovide_input_use_logo = true -- enable use of the logo (cmd) key
  vim.keymap.set('n', '<D-s>', ':w<CR>') -- Save
  vim.keymap.set('v', '<D-c>', '"+y') -- Copy
  vim.keymap.set('n', '<D-v>', '"+P') -- Paste normal mode
  vim.keymap.set('v', '<D-v>', '"+P') -- Paste visual mode
  vim.keymap.set('c', '<D-v>', '<C-R>+') -- Paste command mode
  vim.keymap.set('i', '<D-v>', '<ESC>l"+Pli') -- Paste insert mode

  vim.g.neovide_cursor_animation_length = 0 -- disable cursor animate
  vim.g.neovide_cursor_vfx_mode = "railgun"
  vim.g.neovide_transparency = 0.95
  vim.opt.guifont = { "BlexMono Nerd Font", "h14" }

  vim.env['PATH'] = vim.fn.expand('~/.local/bin:') .. vim.fn.expand('~/miniconda3/bin:') .. vim.env['PATH']
end
