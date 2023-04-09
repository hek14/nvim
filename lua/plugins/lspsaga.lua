return {
  'hek14/lspsaga.nvim',
  branch = 'main',
  enabled = true,
  event = "BufRead",
  config = function()
    require("lspsaga").setup({
      symbol_in_winbar = { enable = false },
      finder = {
        keys = {
          jump_to = 'p',
          edit = { 'o', '<CR>' },
          vsplit = 's',
          split = 'i',
          tabe = 't',
          tabnew = 'r',
          quit = { 'q', '<ESC>' },
          close_in_preview = '<C-q>'
        },
      },
    })
    local au = require('core.autocmds').au
    au('FileType', {
      callback = function ()
        vim.defer_fn(function ()
          vim.keymap.set('n','e','k',{noremap=true,nowait=true,silent=true,buffer=true})
        end,5)
      end,
      pattern = 'lspsagafinder'
    })
      
  end,
  dependencies = {
    {"nvim-tree/nvim-web-devicons"},
    {"nvim-treesitter/nvim-treesitter"}
  }
}
