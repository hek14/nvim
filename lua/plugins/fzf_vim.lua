local M = {
  'ojroques/nvim-lspfuzzy',
  -- 'gfanto/fzf-lsp.nvim',
  enabled = false,
  lazy = false,
  dependencies = {
    {'junegunn/fzf'},
    {'junegunn/fzf.vim'},
    -- you also need to install bat for preview.
  },
  config = function()
    require('lspfuzzy').setup({})
    -- require('fzf_lsp').setup()
  end
}
return M
