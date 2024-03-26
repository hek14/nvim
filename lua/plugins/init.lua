local map = require('core.utils').map
local plugins = {
  {
    "ms-jpq/lua-async-await",
    lazy = false,
    config = function()
      local a = require("async")
      _G.a = a
      a.schedule = function()
        a.wait(function(f)
          vim.schedule(f)
        end)
      end
    end
  },
  {
    "hek14/layman.nvim",
    lazy = false,
    config = function()
      require("layman").setup()
    end
  },
  {
    "Shatur/neovim-session-manager",
    cmd = "SessionManager"
  },
  {
    "willothy/flatten.nvim",
    config = true,
    lazy = false,
  },
  {
    "coffebar/transfer.nvim",
    dependencies = "nvim-neo-tree/neo-tree.nvim",
    cmd = { "TransferInit", "DiffRemote", "TransferUpload", "TransferDownload", "TransferDirDiff", "TransferRepeat" },
    keys = {
      {"<leader>ss", "<Cmd>TransferUpload .<CR>"},
      {"<leader>sd", "<Cmd>TransferDownload .<CR>"},
    },
    opts = {
      config_template = [[
return {
  ["server1"] = {
    host = "qingdao",
    mappings = {
      {
        ["local"] = ".",
        ["remote"] = "/home/heke/",
      },
    },
  },
}
]],
      upload_rsync_params = {
        "-arlzi",
        -- "--delete",
        "--checksum",
        "--exclude-from=" .. vim.env["HOME"] .. "/.rg_ignore"
      },
      download_rsync_params = {
        "-arlzi",
        -- "--delete",
        "--checksum",
        "--exclude-from=" .. vim.env["HOME"] .. "/.rg_ignore"
      },
    },
  },
  {
    "folke/noice.nvim",
    event = "CursorHold",
    -- NOTE: You can write your own CursorHold autocmd to load the plugin at idling time of the main loop.
    -- init = function()
    --   vim.api.nvim_create_autocmd({"CursorHold", "CursorHoldI"}, {
    --     group = vim.api.nvim_create_augroup("kk-cursorhold", {clear=true}),
    --     callback = function()
    --       require("lazy").load({plugins = {"noice.nvim"}})
    --     end,
    --     once = true
    --   })
    -- end,
    enabled = true,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function()
      require('noice').setup({
        lsp = {
          signature = {
            enabled = false,
          }
        },
        routes = {
          {
            filter = {
              event = "msg_show",
              find = "written",
            },
            opts = {
              skip = true,
              -- action = function()
              --   vim.cmd("messages")
              -- end
            },
          },
        }
      })
      map("n", "<leader>nd", "<Cmd>NoiceDismiss<CR>")
      map("n", "<Esc>", [[:noh | NoiceDismiss<CR>]])
      require('telescope').load_extension('noice')
    end
  },
  {
    "kawre/leetcode.nvim",
    lazy = vim.fn.argv()[1] ~= "leetcode.nvim",
    build = ":TSUpdate html",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim", -- required by telescope
      "MunifTanjim/nui.nvim",
      "nvim-treesitter/nvim-treesitter",
      "rcarriga/nvim-notify",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      clang = "cpp",
      cn = { -- leetcode.cn
        enabled = true, ---@type boolean
        translator = true, ---@type boolean
        translate_problems = true, ---@type boolean
      },
      hooks = {
        LeetQuestionNew = {
          function()
            local buf = vim.api.nvim_get_current_buf()
            local file_name = vim.fn.expand("%:t")
            local first_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
            if(#first_line == 0 or not string.match(first_line[1], "^#include<bits/stdc++.h>")) then
              local lines = {"#include<bits/stdc++.h>", "using namespace std;"}
              vim.api.nvim_buf_set_lines(buf, 0, 0, false, lines)
              vim.cmd[[write]]
            end
            local command = string.format( [[!sed -i 's/[^ ]*\.cpp/%s/g' CMakeLists.txt]], file_name )
            vim.cmd(command)
          end
        },
      },
    },
  },
  {
    "MunifTanjim/nui.nvim"
  },
  {
    "tamton-aquib/keys.nvim",
    cmd = "KeysToggle",
    config = function()
      require("keys").setup {
        enable_on_startup = false,
        win_opts = {
          width = 25
        },
      }
    end
  },
  {
    "utilyre/sentiment.nvim",
    version = "*",
    event = "VeryLazy", -- keep for lazy loading
    opts = {},
    init = function()
      vim.g.loaded_matchparen = 1
    end,
  },
  {
    'cdelledonne/vim-cmake',
    ft = {'c', 'cpp'},
    init = function()
      vim.g.cmake_link_compile_commands = 1
    end,
    keys = {
      {'<leader>cg', '<cmd>CMakeGenerate<cr>'},
      {'<leader>cb', '<cmd>CMakeBuild<cr>'},
      {'<leader>ci', '<cmd>CMakeInstall<cr>'},
      {'<leader>ct', '<cmd>CMakeTest<cr>'},
    }
  },
  {
    'alepez/vim-gtest',
    ft = {'c', 'cpp'},
    keys = {
      {',g', ':GTestCmd '}
    },
  },
  {
    "Pocco81/true-zen.nvim",
    cmd = {'TZNarrow', 'TZFocus', 'TZMinimalist', 'TZAtaraxis'},
    config = function()
      require("true-zen").setup({})
    end,
  },
  {
    'tpope/vim-scriptease',
    cmd = 'Messages',
  },
  {
    "tpope/vim-sleuth",
    event = "BufEnter"
  },
  {
    'tpope/vim-fugitive',
    cmd = {'Git', 'Gedit','Gdiffsplit','Gread','Gwrite','Ggrep','GMove','GDelete','GBrowse'}
  },
  {
    "tpope/vim-surround",
    event = "BufEnter"
  },
  {
    'sbulav/nredir.nvim',
    cmd = 'Nredir',
    init = function()
      vim.cmd[[cnoremap <C-g> <Home>Nredir <End><CR>]]
    end,
  },
  { 'nvim-lua/plenary.nvim' },
  { 'nvim-tree/nvim-web-devicons' },
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
    'lukas-reineke/indent-blankline.nvim',
    main = "ibl",
    event = 'BufEnter',
    opts = {}
  },
  {
    "cohama/lexima.vim",
    lazy = false,
  },
  {
    'windwp/nvim-autopairs',
    version = "*",
    enabled = false,
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup{
        check_ts = true,
        ts_config = { -- will not add a pair on that treesitter node
          lua = { "string", "source" },
        },
        disable_filetype = { "TelescopePrompt", "spectre_panel" },
        ignored_next_char = string.gsub([[ [%w%%%'%[%"%.] ]], "%s+", ""),
      }
      local cmp = require('cmp')
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      cmp.event:on('confirm_done',cmp_autopairs.on_confirm_done())
    end
  },
  {
    'numToStr/Comment.nvim',
    event = 'BufEnter',
    config = function()
      require("Comment").setup {
        opleader = {
          line = "gc",
          block = "gb",
        },
        mappings = {
          basic = true,
          extra = true,
        },
        toggler = {
          line = "gcc",
          block = "gbc",
        },
      }
    end,
  },
  {
    'ggandor/leap.nvim',
    enabled = false,
    event = 'BufRead',
    config = function()
      require('leap').setup({})
      map({ 'n', 'x', 'o' }, '<C-f>', '<Plug>(leap-forward-to)')
      map({ 'n', 'x', 'o' }, '<C-b>', '<Plug>(leap-backward-to)')
      map({ 'n', 'x' }, 'gs', '<Plug>(leap-from-window)')
    end,
  },
  {
    "folke/flash.nvim",
    event = "BufRead",
    config = function()
      require('flash').setup{
        labels = "hneiodtsra",
        label = {
          rainbow = {
            enabled = false,
            shade = 5,
          },
        },
        modes = {
          search = { -- search mode: / and ?
          enabled = false
          }
        }
      }
      vim.cmd [[hi! FlashCurrent guibg=blue]]
      vim.cmd [[hi! FlashLabel guibg=red]]
      vim.cmd [[hi! FlashMatch guibg=gray]]
    end,
    keys = {
      {
        "<C-f>",
        mode = { "n", "x", "o" },
        function()
          -- default options: exact mode, multi window, all directions, with a backdrop
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "<F2>",
        mode = { "n", "o", "x" },
        function()
          -- show labeled treesitter nodes around the cursor
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
    },
  },
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
          for b in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_get_option(b, 'filetype') == 'qf' then
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
          assert(timer)
          timer:start(10,10,vim.schedule_wrap(function()
            vim.api.nvim_buf_call(bufnr, function()
              if vim.w.bqf_enabled then
                vim.cmd [[ set modifiable ]]
                vim.keymap.set('n','<C-s>','<cmd>call qf_refactor#replace()<CR>',{ buffer = bufnr })
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
    -- NOTE: use my own ~/.config/nvim/plugin/qf_refactor.vim
    enabled = false,
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
      map('n', '<C-x>u', function()
        vim.cmd [[ UndotreeToggle ]]
        for _,win in ipairs(require('core.utils').get_all_window_buffer_filetype()) do
          if win.filetype == 'undotree' then
            vim.api.nvim_set_current_win(win.winnr)
            break
          end
        end
      end)
    end,
  },
  {
    'rcarriga/nvim-notify',
    enabled = true,
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
    'sakhnik/nvim-gdb',
    init = function()
      vim.g.nvimgdb_disable_start_keymaps = true
    end,
    keys = {
      {"<leader>dd", [[":GdbStartPDB python -m pdb " . expand('%')]], expr=true },
    },
    config = function()
      vim.cmd([[
      command! GdbExit lua NvimGdb.i():send('exit')
      nnoremap <Leader>dz :GdbExit<CR>
      ]])
    end,
  },
  {
    'ahmedkhalf/project.nvim',
    event = {"BufRead"};
    keys = {
      { "<leader>fp", function ()
        require('telescope').load_extension('projects')
        require'telescope'.extensions.projects.projects{}
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
          'CMakeLists.txt'
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
      -- the projects are read in the source code: setup() -> project.lua init() -> history.lua read_projects_from_history() -> uv.fs_read(history_file,callback), 
      -- the project list is built in an async callback!
      -- which means it will not be executed immediately, so when we first call [[Telescope projects]]
      -- it will call this config part first, `config` will load project and *schedule* the read_projects_from_history, but the project lists are empty right now. 
      -- we can use vim.wait to sync the callback, see notes.md
      -- :help vim.wait says: ` Nvim still processes other events during this time.`
    end,
  },
  {
    'skywind3000/asyncrun.vim',
    dependencies = {
      'preservim/vimux',
      keys = {
        -- tw, th, tv is used for built-in terminal
        {'<leader>tt', function()
          if vim.fn.exists('g:VimuxRunnerIndex') > 0 then
            vim.cmd [[VimuxTogglePane]]
          else
            vim.cmd [[VimuxOpenRunner]]
          end
        end},
        {'<leader>tr', [[:<C-u>call VimuxRunCommand("")<Left><Left>]]},
        {'<leader>tc', [[<Cmd>VimuxInterruptRunner<CR>]]},
        {'<leader>tl', [[<Cmd>VimuxClearTerminalScreen<CR>]]},
      },
      init = function()
        vim.g.VimuxHeight = '30'
      end,
    },
    cmd = 'AsyncRun',
    config = function()
      vim.g.asyncrun_open = 10
    end,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = 'python',
        callback = function()
          map('n', ',t', ':AsyncRun -raw -cwd=$(VIM_FILEDIR) python "$(VIM_FILEPATH)" ', {silent = false, buffer = true})
        end
      })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {'cpp', 'c'},
        callback = function()
          map('n', ',t', ':AsyncRun -raw -cwd=$(VIM_FILEDIR) ./Debug/main', {silent = false, buffer = true})
        end
      })
      vim.api.nvim_create_user_command("AsyncRunToggle", [[:call asyncrun#quickfix_toggle(10)]],{})
      vim.g.asyncrun_open = 6
      vim.g.asyncrun_bell = 1
    end,
  },
  {
    'folke/persistence.nvim',
    enabled = false,
    event = 'BufReadPre',
    init = function()
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
    config = function()
      local hl = require('todo-comments.highlight')
      local highlight_win = hl.highlight_win
      hl.highlight_win = function(win, force)
        pcall(highlight_win, win, force)
      end
      require('todo-comments').setup({
        keywords = {
          FIX = {
            icon = ' ',
            color = 'error',
            alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE', 'MAYBE' },
            signs = true,
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
  {
    'lervag/vimtex',
    ft = 'tex',
    init = function()
      vim.g.vimtex_motion_enabled = 0
      vim.g.vimtex_text_obj_enabled = 0
    end,
    config = function()
      vim.g.vimtex_compiler_latexmk_engines = {
        ['_']                = '-xelatex',
        ['pdfdvi']           = '-pdfdvi',
        ['pdfps']            = '-pdfps',
        ['pdflatex']         = '-pdf',
        ['luatex']           = '-lualatex',
        ['lualatex']         = '-lualatex',
        ['xelatex']          = '-xelatex',
        ['context (pdftex)'] = '-pdf -pdflatex=texexec',
        ['context (luatex)'] = '-pdf -pdflatex=context',
        ['context (xetex)']  = [[-pdf -pdflatex=''texexec --xtx'']],
      }
      vim.g.vimtex_view_method = 'skim'
    end,
  },
  {
    'rhysd/vim-grammarous',
    enabled = false,
    init = function()
      vim.g['grammarous#languagetool_cmd'] = 'languagetool -l en-US'
    end,
  },
  -- {
  --   'norcalli/nvim-colorizer.lua',
  --   cmd = 'ColorizerToggle',
  --   config = function()
  --     require('colorizer').setup()
  --   end,
  -- },
  -- {
  --   't9md/vim-choosewin',
  --   enabled = false,
  --   event = 'VimEnter',
  --   config = function()
  --     vim.g.choosewin_overlay_enable = 1
  --     map('core.utils').map('n', '-', '<Plug>(choosewin)', { noremap = false })
  --   end,
  -- },
}
return plugins
