local plugins = {
  {
    'tpope/vim-fugitive',
    cmd = {'Git', 'Gedit','Gdiffsplit','Gread','Gwrite','Ggrep','GMove','GDelete','GBrowse'}
  },
  {
    'hek14/easyformat.nvim',
    ft = { 'python', 'lua' },
    config = function()
      vim.env['PATH'] = vim.fn.expand('~/.local/share/nvim/mason/bin:') .. vim.env['PATH']
      local configs = require('easyformat.config')
      configs.timeout = 300
      configs.use_default({
        'lua',
      })
      -- configs.python = {
      --   cmd = 'black',
      --   args = {},
      --   find = false,
      --   fname = true,
      --   stdin = false,
      --   do_not_need_stdout = true,
      -- }
      configs.python = {
        cmd = 'black',
        args = {'-'},
        stdin = true,
      }
      configs.lua = {
        cmd = 'stylua',
        args = {},
        find = '.stylua.toml',
        fname = true,
        stdin = false,
        do_not_need_stdout = true,
      }
      require('easyformat').setup({
        fmt_on_save = false,
      })
    end,
  },
  {
    'SmiteshP/nvim-gps',
    keys = {
      {
        ',w',function()
          vim.print(require('nvim-gps').get_location())
        end
      }
    },
    config = function()
      require('nvim-gps').setup()
    end,
  },
  {
    'sbulav/nredir.nvim',
    cmd = 'Nredir',
  },
  {
    'jackMort/ChatGPT.nvim',
    cmd = { 'ChatGPT', 'ChatGPTActAs' },
    config = function()
      require('chatgpt').setup({})
    end,
    dependencies = {
      'MunifTanjim/nui.nvim',
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
    },
  },
  { 'nvim-lua/plenary.nvim' },
  {
    'bfredl/nvim-luadev',
    cmd = 'Luadev',
    keys = {
      '<Plug>(Luadev-RunLine)',
      '<Plug>(Luadev-Run)',
      '<Plug>(Luadev-RunWord)',
      '<Plug>(Luadev-Complete)',
    },
    init = function()
      local map = require('core.utils').map
      map('n', '<C-x>l', '<Plug>(Luadev-RunLine)', { remap = true })
      map('n', '<C-x>r', '<Plug>(Luadev-Run)', { remap = true })
      map('x', '<C-x>r', '<Plug>(Luadev-Run)', { remap = true })
      map('n', '<C-x>w', '<Plug>(Luadev-RunWord)', { remap = true })
      map('i', '<C-x>c', '<Plug>(Luadev-Complete)', { remap = true })
    end,
  },
  { 'nvim-tree/nvim-web-devicons' },
  {
    'glepnir/nerdicons.nvim',
    cmd = 'NerdIcons',
    config = function()
      require('nerdicons').setup({})
    end,
  },
  {
    'glepnir/template.nvim', 
    cmd = {'Template','TemProject'}, 
    config = function()
      require('template').setup({
        temp_dir = '~/.config/nvim/template',
        author = 'hek14',
        email = '1023129548@qq.com',
      })
      require('telescope').load_extension('find_template')
    end
  },
  {
    'norcalli/nvim-colorizer.lua',
    cmd = 'ColorizerToggle',
    config = function()
      require('colorizer').setup()
    end,
  },
  {
    'RRethy/vim-tranquille',
    event = 'BufEnter',
    config = function()
      require('core.utils').map(
        'n',
        'g/',
        '<Plug>(tranquille_search)',
        { noremap = true, silent = true }
      )
    end,
  },
  {
    'lmburns/lf.nvim',
    cmd = 'Lf',
    dependencies = { 
      'nvim-lua/plenary.nvim', 
      {
        'akinsho/toggleterm.nvim',
        cmd = 'ToggleTerm',
        config = function ()
          require("toggleterm").setup()
        end
      }
    },
    opts = {
      winblend = 0,
      highlights = { NormalFloat = { guibg = 'NONE' } },
      border = 'double', -- border kind: single double shadow curved
      height = 0.70,
      width = 0.85,
      escape_quit = true,
    },
    keys = {
      { '<cmd>Lf<cr>', desc = 'lfcd' },
    },
  },
  {
    'echasnovski/mini.sessions',
    version = false,
    lazy = false,
    config = function()
      require('mini.sessions').setup()
    end,
  },
  {
    'echasnovski/mini.surround',
    keys = { 'sa', 'sd', 'sr', 'sf', 'sF', 'sh', 'sn' },
    version = false,
    config = function()
      require('mini.surround').setup()
    end,
  },
  {
    'nvimdev/indentmini.nvim',
    enabled = false,
    event = 'BufEnter',
    config = function()
      require('indentmini').setup({
        exclude = {'dashboard', 'lazy', 'help', 'markdown', 'terminal', 'floaterm', 'vim'}
      })
    end,
    -- this is no required but if you want indent blanklink line this is needed
    dependencies = { 'nvim-treesitter/nvim-treesitter'}
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    enabled = false,
    event = 'VimEnter',
    config = function()
      local default = {
        indentLine_enabled = 1,
        char = '▏',
        filetype_exclude = {
          'help',
          'terminal',
          'alpha',
          'lspinfo',
          'TelescopePrompt',
          'TelescopeResults',
        },
        buftype_exclude = { 'terminal' },
        show_trailing_blankline_indent = false,
        show_first_indent_level = false,
      }
      require('indent_blankline').setup(default)
    end,
  },
  {
    'luukvbaal/statuscol.nvim',
    enabled = false,
    -- enabled = function()
    --   local v = vim.fn.has('nvim-0.9')
    --   if v == 1 then
    --     return true
    --   else
    --     return false
    --   end
    -- end,
    event = 'BufRead',
    config = function()
      require('statuscol').setup({ setopt = true })
    end,
  },
  {
    'simrat39/symbols-outline.nvim',
    cmd = { 'SymbolsOutline' },
    config = function()
      local opts = {
        keymaps = {
          fold = 'f',
          unfold = 'F',
        },
      }
      require('symbols-outline').setup(opts)
      require('core.utils').map("n","<leader>ls",":SymbolsOutline<CR>")
    end,
  },
  {
    'folke/trouble.nvim',
    config = function()
      require('trouble').setup({})
    end,
  },
  {
    'max397574/better-escape.nvim',
    event = 'InsertCharPre',
    config = function()
      local default = {
        mapping = { 'jk' },
        timeout = 300,
      }
      require('better_escape').setup(default)
    end,
  },
  -- misc plugins
  {
    'windwp/nvim-autopairs',
    config = true,
    event = 'InsertEnter',
  },
  {
    'numToStr/Comment.nvim',
    keys = { 'gcc' },
    config = true,
    init = function()
      local map = require('core.utils').map
      map('n', '<leader>/', ":lua require('Comment.api').toggle.linewise.current()<CR>")
      map('v', '<leader>/', ":lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>")
    end,
  },
  -- file managing , picker etc
  {
    'ThePrimeagen/harpoon',
    keys = {
      { '<leader>ma', "<cmd>lua require('harpoon.mark').add_file()<cr>", desc = 'harpoon add' },
      {
        '<leader>mt',
        "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>",
        desc = 'harpoon toggle',
      },
    },
  },
  {
    'sakhnik/nvim-gdb',
    init = function()
      vim.g.nvimgdb_disable_start_keymaps = true
    end,
    config = function()
      vim.cmd([[
      nnoremap <expr> <Leader>dd ":GdbStartPDB python -m pdb " . expand('%')
      ]])
      vim.cmd([[
      command! GdbExit lua NvimGdb.i():send('exit')
      nnoremap <Leader>ds :GdbExit<CR>
      ]])
    end,
  },
  {
    'Pocco81/TrueZen.nvim',
    cmd = { 'TZAtaraxis', 'TZMinimalist', 'TZFocus' },
    init = function()
      require('core.utils').map('n', 'gq', '<cmd>TZFocus<CR>')
      -- require("core.utils").map("i", "<C-q>", "<cmd>TZFocus<CR>")
    end,
  },
  {
    'ggandor/leap.nvim',
    event = 'BufRead',
    config = function()
      require('leap').setup({})
      local map = require('core.utils').map
      map({ 'n', 'x', 'o' }, '<C-f>', '<Plug>(leap-forward-to)')
      map({ 'n', 'x', 'o' }, '<C-b>', '<Plug>(leap-backward-to)')
      map({ 'n', 'x' }, 'gs', '<Plug>(leap-from-window)')
    end,
  },
  -- 1. populate the quickfix
  {
    'mhinz/vim-grepper',
    lazy = false,
    config = function()
      vim.g.grepper = {
        tools = { 'rg', 'grep' },
        searchreg = 1,
        next_tool = '<leader>gw',
      }
      vim.cmd([[
      nnoremap <leader>gw :Grepper<cr>
      nmap <leader>gs  <plug>(GrepperOperator)
      xmap <leader>gs  <plug>(GrepperOperator)
      ]])
    end,
  },
  {
    'kevinhwang91/nvim-bqf',
    ft = 'qf',
    config = function()
      local group = vim.api.nvim_create_augroup('hack_bqf',{clear=true})
      vim.api.nvim_create_autocmd('ExitPre',{
        group = group,
        callback = function()
          print('kill all qf')
          for b in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_get_option(b, 'filetype') == 'qf' then
              vim.api.nvim_buf_delete(b, {force = true})
            end
          end
        end
      })
      vim.api.nvim_create_autocmd('FileType',{
        pattern = 'qf',
        group = group,
        callback = function()
          local timer = vim.loop.new_timer()
          local bufnr = vim.api.nvim_get_current_buf()
          local start = vim.loop.now()
          timer:start(10,10,vim.schedule_wrap(function()
            vim.api.nvim_buf_call(bufnr, function()
              print('current buf: ',vim.api.nvim_get_current_buf())
              if vim.w.bqf_enabled then
                print('bqf loaded ',vim.loop.now()-start)
                vim.cmd [[ set modifiable ]]
                vim.keymap.set('n','<C-s>','<cmd>call qf_refactor#replace()<CR>',{ buffer = bufnr })
                vim.keymap.set('n','q',':bd!<CR>',{ buffer = bufnr })
                if timer then
                  timer:stop()
                  timer:close()
                  timer = nil
                end
              end
            end)
          end))
        end
      })
    end
  },
  {
    'stefandtw/quickfix-reflector.vim',
    enabled = false, -- NOTE: use my own ~/.config/nvim/plugin/qf_refactor.vim

    -- this plugin conflicts with the above nvim-bqf, it will ca nvim-bqf not working, there is two solutions:
    -- soluction 1: defer the nvim-bqf loading just like above
    -- solution 2: modify the quickfix-reflector.vim init_buffer like below:
    -- function! s:PrepareBuffer()
    --   try
    --     lua require('bqf').enable()
    --   catch
    --     echom "nvim-bqf is not installed"
    --   endtry
    --   if g:qf_modifiable == 1
    --     setlocal modifiable
    --   endif
    --   let s:qfBufferLines = getline(1, '$')
    -- endfunction
  },
  {
    'mbbill/undotree',
    cmd = 'UndotreeToggle',
    init = function()
      require('core.utils').map('n', '<C-x>u', ':UndotreeToggle | UndotreeFocus<CR>')
    end,
  },
  {
    'tpope/vim-scriptease',
    enabled = false,
    cmd = 'Messages',
  },
  { 'MunifTanjim/nui.nvim' },
  {
    'rcarriga/nvim-notify',
    enabled = false,
    config = function()
      require('notify').setup({
        background_colour = '#000000',
      })
      vim.notify = require('notify')
    end,
  },
  {
    'iamcco/markdown-preview.nvim',
    build = function()
      vim.fn['mkdp#util#install'](0)
    end,
    init = function()
      vim.g.mkdp_filetypes = { 'markdown' }
      vim.cmd([[
      function! Clippy_open_browser(url) abort
      echom('opening ' . a:url)
      call system('clippy command ssh -N -f -L 9999:127.0.0.1:9999 qingdao')
      call system('clippy openurl ' . a:url)
      endfunction
      ]])
      vim.g.mkdp_browserfunc = 'Clippy_open_browser'
      vim.g.mkdp_port = '9999'
    end,
    ft = { 'markdown' },
  },
  {
    'metakirby5/codi.vim',
    cmd = { 'Codi', 'CodiNew', 'CodiSelect', 'CodiExpand' },
  },
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-neotest/neotest-python',
      'nvim-neotest/neotest-plenary',
      'nvim-neotest/neotest-vim-test',
    },
    init = function()
      vim.api.nvim_create_user_command(
        'TestNearest',
        ":lua require('neotest').run.run()",
        { force = true }
      )
      vim.api.nvim_create_user_command(
        'TestFile',
        ":lua require('neotest').run.run(vim.fn.expand('%'))",
        { force = true }
      )
      vim.api.nvim_create_user_command(
        'TestDebug',
        ":lua require('neotest').run.run({strategy = 'dap'})",
        { force = true }
      )
      vim.api.nvim_create_user_command(
        'TestStop',
        ":lua require('neotest').run.stop()",
        { force = true }
      )
    end,
    config = function()
      require('neotest').setup({
        adapters = {
          require('neotest-python')({
            dap = { justMyCode = false },
          }),
          require('neotest-plenary'),
          require('neotest-vim-test')({
            ignore_file_types = { 'python', 'vim', 'lua' },
          }),
        },
      })
    end,
  },
  {
    'ahmedkhalf/project.nvim',
    event = "VeryLazy",
    keys = {
      { "<leader>fp", function ()
        require('telescope').load_extension('projects')
        require'telescope'.extensions.projects.projects{}
        -- vim.cmd [[ Telescope projects ]] 
      end
    }},
    name = 'project.nvim',
    config = function()
      require('project_nvim').setup({
        manual_mode = false,
        detection_methods = { 'pattern' },
        patterns = {
          '.git',
          '.project',
          'pyproject.toml',
          'pyrightconfig.json',
          '_darcs',
          '.hg',
          '.bzr',
          '.svn',
          'Makefile',
          'package.json',
          'main.py',
          'trainer*.py',
        },
        exclude_dirs = {},
        show_hidden = false,
        silent_chdir = true,
        datapath = vim.fn.stdpath('data'),
      })
      -- NOTE: important: just change root per window
      vim.cmd([[autocmd WinEnter * ++nested lua require("project_nvim.project").on_buf_enter()]])
      vim.wait(5, function ()
        return false
      end)
      -- NOTE: why do this here? 
      -- the projects are read in the source code: project.lua -> M.init() -> history.read_projects_from_history() -> uv.fs_read(history_file), this is a async callback!
      -- which means it will not be executed immediately, so when we first call [[Telescope projects]]
      -- it will call this config part first, `config` will load project and *schedule* the read_projects_from_history, but the project lists are empty right now. 
      -- we can use vim.wait to sync the callback, see notes.md
    end,
  },
  {
    'skywind3000/asynctasks.vim',
    cmd = 'AsyncTask',
    init = function()
      vim.g.asyncrun_open = 6
    end,
    dependencies = {
      {
        'skywind3000/asyncrun.vim',
        -- << NOTE: macros
        -- $(VIM_FILEPATH)  - File name of current buffer with full path
        -- $(VIM_FILENAME)  - File name of current buffer without path
        -- $(VIM_FILEDIR)   - Full path of current buffer without the file name
        -- $(VIM_FILEEXT)   - File extension of current buffer
        -- $(VIM_FILENOEXT) - File name of current buffer without path and extension
        -- $(VIM_PATHNOEXT) - Current file name with full path but without extension
        -- $(VIM_CWD)       - Current directory
        -- $(VIM_RELDIR)    - File path relativize to current directory
        -- $(VIM_RELNAME)   - File name relativize to current directory
        -- $(VIM_ROOT)      - Project root directory
        -- $(VIM_CWORD)     - Current word under cursor
        -- $(VIM_CFILE)     - Current filename under cursor
        -- $(VIM_GUI)       - Is running under gui ?
        -- $(VIM_VERSION)   - Value of v:version
        -- $(VIM_COLUMNS)   - How many columns in vim's screen
        -- $(VIM_LINES)     - How many lines in vim's screen
        -- $(VIM_SVRNAME)   - Value of v:servername for +clientserver usage
        -- $(VIM_PRONAME)   - Name of current project root directory
        -- $(VIM_DIRNAME)   - Name of current directory
        -- >> END
        dependencies = {
          'preservim/vimux',
          init = function()
            vim.g.VimuxHeight = '30'
          end,
        },
        cmd = 'AsyncRun',
        init = function()
          local ft_map = require('core.autocmds').ft_map
          ft_map(
            'python',
            'n',
            ',t',
            '<cmd>AsyncRun -cwd=$(VIM_FILEDIR) python "$(VIM_FILEPATH)"<CR>'
          )
        end,
      },
    },
  },
  {
    'folke/persistence.nvim',
    enabled = false, -- use very few times, but consume too much time at startup
    event = 'BufReadPre', -- this will only start session saving when an actual file was opened
    init = function()
      -- this mapping should be in the init module, to that before the loading of whick-key, otherwise it will not work
      local map = require('core.utils').map
      map('n', '<space>qs', [[<cmd>lua require("persistence").load()<cr>]])
      map('n', '<space>ql', [[<cmd>lua require("persistence").load({ last = true })<cr>]])
      map('n', '<space>qd', [[<cmd>lua require("persistence").stop()<cr>]])
    end,
    config = function()
      require('persistence').setup({
        dir = vim.fn.expand(vim.fn.stdpath('data') .. '/sessions/'),
        options = { 'buffers', 'curdir', 'tabpages', 'winsize' },
      })
    end,
  },
  {
    'folke/todo-comments.nvim',
    -- how to use it?
    -- using TODO: (the last colon is necessary)
    event = 'BufRead',
    dependencies = 'nvim-lua/plenary.nvim',
    config = function()
      -- HACK: #104 Invalid in command-line window
      local hl = require('todo-comments.highlight')
      local highlight_win = hl.highlight_win
      hl.highlight_win = function(win, force)
        pcall(highlight_win, win, force)
      end
      require('todo-comments').setup({
        keywords = {
          FIX = {
            icon = ' ', -- icon used for the sign, and in search results
            color = 'error', -- can be a hex color, or a named color (see below)
            alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE', 'MAYBE' }, -- a set of other keywords that all map to this FIX keywords
            signs = true, -- configure signs for some keywords individually
          },
        },
      })
    end,
  },
  {
    'sindrets/diffview.nvim',
    cmd = 'DiffviewOpen',
    dependencies = 'nvim-lua/plenary.nvim',
  },
  {
    'nvim-pack/nvim-spectre',
    keys = {
      { '<leader>S', "<cmd>lua require('spectre').open()<CR>" },
      { '<leader>sc', "<cmd>lua require('spectre').open_file_search()<CR>" },
      { '<leader>sw', "<cmd>lua require('spectre').open_visual({select_word=true})<CR>" },
      { '<leader>s', "<cmd>lua require('spectre').open_visual()<CR>" },
    },
    -- NOTE: to make this work, you should have `gsed` in the $PATH `ln -s ~/.nix-profile/bin/sed ~/.local/bin/gsed`
    config = function()
      require('spectre').setup({ replace_engine = { sed = { cmd = 'sed' } } })
    end,
  },
  {
    't9md/vim-choosewin',
    enabled = false,
    event = 'VimEnter',
    config = function()
      vim.g.choosewin_overlay_enable = 1
      require('core.utils').map('n', '-', '<Plug>(choosewin)', { noremap = false })
    end,
  },
  {
    'alexghergh/nvim-tmux-navigation',
    event = 'VeryLazy',
    config = function()
      require('nvim-tmux-navigation').setup({
        disable_when_zoomed = true, -- defaults to false
        keybindings = {
          left = '<C-LEFT>',
          down = '<C-DOWN>',
          up = '<C-UP>',
          right = '<C-RIGHT>',
          last_active = '<C-\\>',
          next = '<C-Space>',
        },
      })
    end,
  },
  { 'kdheepak/cmp-latex-symbols' },
  {
    'lervag/vimtex',
    ft = 'tex',
    init = function()
      vim.g.vimtex_motion_enabled = 0
      vim.g.vimtex_text_obj_enabled = 0
    end,
    config = function()
      vim.g.vimtex_view_method = 'skim'
      vim.cmd([[
      let maplocalleader = ","
      ]])
    end,
  },
  {
    'rhysd/vim-grammarous',
    enabled = false, -- very hard to : cannot ignore the latex keywords
    init = function()
      vim.g['grammarous#languagetool_cmd'] = 'languagetool -l en-US'
    end,
  },
}
return plugins
