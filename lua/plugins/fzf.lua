-- documentation: https://github.com/ibhagwan/fzf-lua/wiki/Advanced
return {
  'ibhagwan/fzf-lua',
  enabled = false,
  cmd = 'FzfLua',
  dependencies = {
    {'nvim-tree/nvim-web-devicons'},
  },
  keys = {
    { "<leader>b", "<cmd>FzfLua buffers<CR>" },
    { "<leader>ff", "<cmd>FzfLua files<CR>"},
    { "<leader>fg", "<cmd>FzfLua git_commits<CR>" },
    { "<leader>gs", "<cmd>FzfLua git_status<CR>" },
    { "<leader>fh", "<cmd>FzfLua help_tags<CR>" },
    { "<leader>fo", "<cmd>FzfLua oldfiles<CR>" },
    { "<leader>fd", "<cmd>FzfLua cwd=~/.config/nvim<CR>" },
    { "<leader>fr", "<cmd>FzfLua resme<CR>" },
    { "<leader>fk", "<cmd>FzfLua keymaps<CR>" },
    { '<leader>fs', '<Cmd>FzfLua blines<CR>' },
    { "<leader>fw", "<cmd>FzfLua live_grep<CR>"},
    { "<leader><leader>w", "<cmd>FzfLua grep_cword<CR>"},
    { "<leader>sd", function ()
      require('fzf-lua').live_grep({
        cwd = '/usr/local/share/nvim/runtime/doc/'
      })
    end }
  },
  config = function ()
    require('fzf-lua').setup({
      fzf_opts = {
        ['--layout'] = 'reverse',
      },
    })
  end
}
