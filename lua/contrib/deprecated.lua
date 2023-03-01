local plugins = {
  {
    "kylechui/nvim-surround",
    enabled = false,
    event = "BufEnter",
    config = function()
      require("nvim-surround").setup()
    end,
  },
  {
    'romgrk/barbar.nvim',
    enabled = false,
    event = 'VeryLazy',
    config = function ()
      require'bufferline'.setup({
        icons = 'numbers'
      })
      local map = require("core.utils").map
      map('n', '<leader>1', '<Cmd>BufferGoto 1<CR>')
      map('n', '<leader>2', '<Cmd>BufferGoto 2<CR>')
      map('n', '<leader>4', '<Cmd>BufferGoto 4<CR>')
      map('n', '<leader>5', '<Cmd>BufferGoto 5<CR>')
      map('n', '<leader>6', '<Cmd>BufferGoto 6<CR>')
      map('n', '<leader>7', '<Cmd>BufferGoto 7<CR>')
      map('n', '<leader>8', '<Cmd>BufferGoto 8<CR>')
      map('n', '<leader>9', '<Cmd>BufferGoto 9<CR>')
      map('n', '<leader>0', '<Cmd>BufferLast<CR>')
      map('n', '[b', '<Cmd>BufferPrevious<CR>')
      map('n', ']b', '<Cmd>BufferNext<CR>')
    end
  },
  {
    "rrethy/vim-hexokinase",
    enabled = false, -- NOTE: slow
    cond = function()
      return vim.fn.executable('go')==1
    end,
    build = "make hexokinase",
    event = "BufRead"
  },
  {
    "tmhedberg/SimpylFold",
    enabled = false,
    config = function()
      vim.g.SimpylFold_docstring_preview = 1
    end,
  },
  {
    "ronakg/quickr-preview.vim",
    enabled = false,
    -- deprecated: using myself core.utils.preview_qf()
    config = function()
      vim.g.quickr_preview_keymaps = 0
      vim.cmd([[
      augroup qfpreview
      autocmd!
      autocmd FileType qf nmap <buffer> p <plug>(quickr_preview)
      autocmd FileType qf nmap <buffer> q exe "normal \<plug>(quickr_preview_qf_close)<CR>"
      augroup END
      ]])
    end,
  },
  {
    'VonHeikemen/searchbox.nvim',
    enabled = false, -- NOTE: can't resume previous/next search history
    dependencies = {
      {'MunifTanjim/nui.nvim'}
    },
    config = function ()
      require("core.utils").map('n','/',":lua require('searchbox').match_all()<CR>")
      require("core.utils").map('x','/',"<Esc>:lua require('searchbox').match_all({visual_mode = true})<CR>")
      require("core.utils").map('n','?',":lua require('searchbox').match_all({reverse=true})<CR>")
      require("core.utils").map('x','?',"<Esc>:lua require('searchbox').match_all({visual_mode = true,reverse = true})<CR>")
    end
  },
  {
    "stevearc/dressing.nvim",
    enabled = false,
    event = "VimEnter",
    config = function()
      require("dressing").setup({})
    end,
  },
  {
    "folke/noice.nvim",
    enabled = false, -- currently very unstable
    event = 'VimEnter',
    config = function()
      require("noice").setup({
        lsp = {
          hover = {
            enabled = false
          },
          signature = {
            enabled = false
          }
        },
      })
    end,
    requires = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    }
  },
  {
    "danilamihailov/beacon.nvim",
    enabled = false, -- disabled because of buggy on OSX
  },
  {
    "folke/which-key.nvim",
    enabled = false,
    config = function()
      require("which-key").setup {}
    end
  },
  {
    "djoshea/vim-autoread",
    enabled = false,
  },
  {
    'ldelossa/litee.nvim',
    enabled = false, -- feel slow
    dependencies = {
      {'ldelossa/litee-calltree.nvim',enabled = false},
      {'ldelossa/litee-symboltree.nvim',enabled = false},
    },
    config = function()
      require('litee.lib').setup({})
      require('litee.calltree').setup({})
      require('litee.symboltree').setup({})
    end
  },
  {
    "ghillb/cybu.nvim",
    enabled = false,
    lazy = false,
    config = function()
      local ok, cybu = pcall(require, "cybu")
      if not ok then
        return
      end
      cybu.setup()
      require('core.utils').map("n", "<leader>n", "<Plug>(CybuNext)",{})
      require('core.utils').map("n", "<leader>e", "<Plug>(CybuPrev)",{})
    end,
  },
  {
    "habamax/vim-winlayout",
    lazy = false,
    enabled = false,
    config = function()
      require('core.utils').map("n", ",,", "<Plug>(WinlayoutBackward)",{})
      require('core.utils').map("n", "..", "<Plug>(WinlayoutForward)",{})
    end
  }
}


local lprint = require("core.utils").log
-- deprecated: use :Lazy profile instead
-- vim.api.nvim_create_autocmd("UIEnter", {
--   callback = function()
--     local is_mac = vim.loop.os_uname().sysname=="Darwin"
--     if is_mac then
--       print('please use startuptime to profile')
--       return
--     else
--       local pid = vim.loop.os_getpid()
--       local ctime = vim.loop.fs_stat("/proc/" .. pid).ctime
--       local start = ctime.sec + ctime.nsec / 1e9
--       local tod = { vim.loop.gettimeofday() }
--       local now = tod[1] + tod[2] / 1e6
--       local startuptime = (now - start) * 1000
--       vim.notify("startup: " .. startuptime .. "ms")
--     end
--   end,
-- })
function Buf_attach()
  -- reset keymaps
  vim.defer_fn(function ()
    local cmd_str = [[xunmap <buffer> ih]] -- NOTES: xunmap ih will not work in this case!!! buffer local keymaps should unmap using <buffer> too
    local ok_all = true
    lprint(cmd_str)
    local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok

    cmd_str = [[ounmap <buffer> ih]]
    lprint(cmd_str)
    ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok

    cmd_str = [[xunmap i%]]
    lprint(cmd_str)
    ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok

    cmd_str = [[ounmap i%]]
    lprint(cmd_str)
    ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok
  end,250) -- 250 should be enough for buffer local plugins to load
  -- require("core.utils").repeat_timer(function ()
    --   local bufnr = vim.api.nvim_get_current_buf()
    --   if vim.api.nvim_buf_is_valid(bufnr) then
    --     local ok,timer = pcall(vim.api.nvim_buf_get_var,bufnr,'timer')
    --     if not ok then
    --       timer = 0
    --     else
    --       timer = vim.api.nvim_buf_get_var(bufnr,'timer')
    --     end
    --     local ok_all = true
    --
    --     local cmd_str = [[xunmap <buffer> ih]] -- NOTES: xunmap ih will not work in this case!!! buffer local keymaps should unmap using <buffer> too
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     local cmd_str = [[ounmap <buffer> ih]]
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     local cmd_str = [[xunmap i%]]
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     local cmd_str = [[ounmap i%]]
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     -- local cmd_str = [[lua vim.api.nvim_buf_del_keymap(]] .. tostring(bufnr) .. [[ , 'x' , 'i%')]]
    --     -- lprint(cmd_str)
    --     -- local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     -- ok_all = ok_all and ok
    --
    --     if packer_plugins['vim-matchup'].loaded then
    --       vim.api.nvim_buf_set_keymap(bufnr,'x','u%','<Plug>(matchup-i%)',{silent=true, noremap=false})
    --     end
    --     if packer_plugins['gitsigns.nvim'].loaded then
    --       vim.api.nvim_buf_set_keymap(bufnr,'x','uh',':<C-U>Gitsigns select_hunk<CR>',{silent=true, noremap=false})
    --       vim.api.nvim_buf_set_keymap(bufnr,'o','uh',':<C-U>Gitsigns select_hunk<CR>',{silent=true, noremap=false})
    --     end
    --     if ok then
    --       return -1
    --     else
    --       if timer<300 then
    --         vim.api.nvim_buf_set_var(bufnr,"timer",timer+10)
    --         return 10
    --       else
    --         return -1
    --       end
    --     end
    --   end
    -- end)
  end
vim.cmd([[autocmd BufEnter * lua Buf_attach()]])
