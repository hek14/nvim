local plugins = {
  { "nvim-lua/plenary.nvim" , lazy = false },
  { "nvim-tree/nvim-web-devicons" },
  {
    "norcalli/nvim-colorizer.lua",
    event = "BufEnter",
    config = function ()
      require'colorizer'.setup()
    end
  },
  {
    'RRethy/vim-tranquille',
    lazy = false, 
    config = function ()
      require('core.utils').map('n','g/','<Plug>(tranquille_search)',{ noremap = true, silent = true }) 
    end
  },
  {
    "lmburns/lf.nvim",
    cmd = "Lf",
    dependencies = { "nvim-lua/plenary.nvim", "akinsho/toggleterm.nvim" },
    opts = {
      winblend = 0,
      highlights = { NormalFloat = { guibg = "NONE" } },
      border = "double", -- border kind: single double shadow curved
      height = 0.70,
      width = 0.85,
      escape_quit = true,
    },
    keys = {
      { "<cmd>Lf<cr>", desc = "lfcd" },
    },
  },
  {
    "utilyre/barbecue.nvim", -- NOTE: for this to work well, should use SFMono Nerd Font for terminal
    dependencies = { 'hek14/nvim-navic', 'nvim-tree/nvim-web-devicons' },
    name = "barbecue",
    event = 'BufRead',
    opts = {},
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
    "lukas-reineke/indent-blankline.nvim",
    event = "VimEnter",
    config = function ()
      local default = {
        indentLine_enabled = 1,
        char = "▏",
        filetype_exclude = {
          "help",
          "terminal",
          "alpha",
          "lspinfo",
          "TelescopePrompt",
          "TelescopeResults",
        },
        buftype_exclude = { "terminal" },
        show_trailing_blankline_indent = false,
        show_first_indent_level = false,
      }
      require("indent_blankline").setup(default)
    end
  },
  {
    'kevinhwang91/nvim-ufo',
    enabled = false,
    event = 'BufEnter',
    dependencies = 'kevinhwang91/promise-async',
    config = function ()
      local map = require("core.utils").map
      map('n', 'zR', require('ufo').openAllFolds)
      map('n', 'zM', require('ufo').closeAllFolds)
    end
  },
  {
    "luukvbaal/statuscol.nvim",
    event = 'BufRead',
    config = function() 
      require("statuscol").setup({setopt = true}) 
    end
  },
  {
    "simrat39/symbols-outline.nvim",
    cmd = { "SymbolsOutline" },
    config = function()
      opts = {
        keymaps = {
          fold = "f",
          unfold = "F",
        }
      }
      require("symbols-outline").setup(opts)
    end
  },
  {
    'hek14/nvim-navic',
    config = function ()
      require('core.utils').map("n", '[g', "<Cmd>lua require('nvim-navic').goto_last_context()<CR>", {silent=false})
    end
  },
  {
    "folke/trouble.nvim",
    config = function()
      require("trouble").setup({})
    end,
  },
  {
    "hek14/vim-illuminate",
    event = "BufRead",
    config = function ()
      vim.g.Illuminate_delay = 17
    end
  },
  {
    "andymass/vim-matchup",
    enabled = false,
    event = 'BufRead',
    init = function()
      vim.g.matchup_text_obj_enabled = 0
      vim.g.matchup_surround_enabled = 1
    end,
  },
  {
    "max397574/better-escape.nvim",
    event = "InsertCharPre",
    config = function ()
      local default = {
        mapping = {'jk'},
        timeout = 300,
      }
      require("better_escape").setup(default)
    end
  },
  -- misc plugins
  {
    "windwp/nvim-autopairs",
    config = true,
    event = 'InsertEnter',
  },
  {
    "numToStr/Comment.nvim",
    keys = { "gcc" },
    config = true,
    init = function()
      local map = require("core.utils").map
      map("n", "<leader>/", ":lua require('Comment.api').toggle.linewise.current()<CR>")
      map("v", "<leader>/", ":lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>")
    end,
  },
  -- file managing , picker etc
  {
    'ThePrimeagen/harpoon',
    keys = {
      { "<leader>ma", "<cmd>lua require('harpoon.mark').add_file()<cr>", desc = "harpoon add" },
      { "<leader>mt", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", desc = "harpoon toggle" },
    },
  },
  {
    "tversteeg/registers.nvim",
    enabled = false,
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
    "sakhnik/nvim-gdb",
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
    "Pocco81/TrueZen.nvim",
    cmd = { "TZAtaraxis", "TZMinimalist", "TZFocus" },
    init = function()
      require("core.utils").map("n", "gq", "<cmd>TZFocus<CR>")
      -- require("core.utils").map("i", "<C-q>", "<cmd>TZFocus<CR>")
    end,
  },
  {
    "kylechui/nvim-surround",
    event = "BufEnter",
    config = function()
      require("nvim-surround").setup()
    end,
  },
  {
    "ggandor/leap.nvim",
    event = 'BufEnter',
    config = function()
      require('leap').add_default_mappings()
    end
  },
  -- 1. populate the quickfix
  {
    "mhinz/vim-grepper",
    lazy = false,
    config = function()
      vim.g.grepper =
      {
        tools = { "rg", "grep" },
        searchreg = 1,
        next_tool = "<leader>gw",
      }
      vim.cmd([[
      nnoremap <leader>gw :Grepper<cr>
      nmap <leader>gs  <plug>(GrepperOperator)
      xmap <leader>gs  <plug>(GrepperOperator)
      ]])
    end,
  },
  -- 2. better qf buffer
  {
    "kevinhwang91/nvim-bqf",
    enabled = false,
    -- deprecated: using myself core.utils.preview_qf()
    -- config = function()
      --   -- need this to  with quickfix-reflector
      --   vim.cmd([[
      --     augroup nvim-bqf-kk
      --       autocmd FileType qf lua vim.defer_fn(function() require('bqf').enable() end,50)
      --       augroup END
      --     ]])
      -- end,
    },
    -- 3. editable qf (similar to emacs wgrep)
    {
      "stefandtw/quickfix-reflector.vim",
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
    }, -- 4. preview location
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
      "mbbill/undotree",
      cmd = "UndotreeToggle",
      init = function()
        require("core.utils").map("n", "<C-x>u", ":UndotreeToggle | UndotreeFocus<CR>")
      end,
    },
    {
      "dstein64/vim-startuptime",
      lazy = false,
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
    { "tpope/vim-scriptease", lazy=false },
    { "MunifTanjim/nui.nvim" },
    {
      "danilamihailov/beacon.nvim",
      enabled = false, -- disabled because of buggy on OSX
    },
    {
      "rcarriga/nvim-notify",
      event = "VeryLazy",
      config = function()
        require('notify').setup(
        {
          background_colour = "#000000",
        })
        vim.notify = require("notify")
      end,
    },
    {
      "iamcco/markdown-preview.nvim",
      build = function()
        vim.fn["mkdp#util#install"](0)
      end,
      init = function()
        vim.g.mkdp_filetypes = { "markdown" }
        vim.cmd([[
        function! Clippy_open_browser(url) abort
        echom('opening ' . a:url)
        call system('clippy openurl ' . a:url)
        endfunction
        ]])
        vim.g.mkdp_browserfunc = "Clippy_open_browser"
        vim.g.mkdp_port = "9999"
      end,
      ft = { "markdown" },
    },
    { 'michaelb/sniprun',
    -- replace it with codi.nvim
    enabled = false,
    build = 'bash ./install.sh'
  },
  {
    "metakirby5/codi.vim",
    init = function()
      vim.cmd[[
      let g:codi#interpreters = {
        \ 'python': {
          \ 'bin': 'python',
          \ 'prompt': '^\(>>>\|\.\.\.\) ',
          \ },
          \ }
          ]]
        end
      },
      {
        "nvim-neotest/neotest",
        dependencies = {
          "nvim-lua/plenary.nvim",
          "nvim-treesitter/nvim-treesitter",
          "antoinemadec/FixCursorHold.nvim",
          "nvim-neotest/neotest-python",
          "nvim-neotest/neotest-plenary",
          "nvim-neotest/neotest-vim-test"
        },
        init = function ()
          vim.api.nvim_create_user_command("TestNearest", ":lua require('neotest').run.run()", {force=true})
          vim.api.nvim_create_user_command("TestFile", ":lua require('neotest').run.run(vim.fn.expand('%'))", {force=true})
          vim.api.nvim_create_user_command("TestDebug", ":lua require('neotest').run.run({strategy = 'dap'})", {force=true})
          vim.api.nvim_create_user_command("TestStop", ":lua require('neotest').run.stop()", {force=true})
        end,
        config = function ()
          require("neotest").setup({
            adapters = {
              require("neotest-python")({
                dap = { justMyCode = false },
              }),
              require("neotest-plenary"),
              require("neotest-vim-test")({
                ignore_file_types = { "python", "vim", "lua" },
              }),
            },
          })
        end
      },
      {
        "ahmedkhalf/project.nvim",
        name = 'project.nvim',
        lazy = false,
        config = function ()
          require("project_nvim").setup {
            manual_mode = false,
            detection_methods = { "pattern" }, 
            patterns = { ".git", ".project", 'pyproject.toml', 'pyrightconfig.json', "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", "main.py", "trainer*.py"},
            exclude_dirs = {},
            show_hidden = false,
            silent_chdir = true,
            datapath = vim.fn.stdpath("data"),
          }
          -- NOTE: important: just change root per window
          vim.cmd[[autocmd WinEnter * ++nested lua require("project_nvim.project").on_buf_enter()]]
        end
      },
      {
        "skywind3000/asynctasks.vim",
        cmd = 'AsyncTask',
        dependencies = { 
          { 
            "skywind3000/asyncrun.vim", 
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
              "preservim/vimux",
              init = function()
                vim.g.VimuxHeight = "30"
              end
            },
            cmd = 'AsyncRun',
            init = function ()
              local ft_map = require("core.autocmds").ft_map
              ft_map('python','n',',t','<cmd>AsyncRun -cwd=$(VIM_FILEDIR) python "$(VIM_FILEPATH)"<CR>')
            end
          },
        },
        init = function ()
          vim.g.asyncrun_open = 6
        end
      },
      {
        "folke/persistence.nvim",
        event = "BufReadPre", -- this will only start session saving when an actual file was opened
        init = function ()
          -- this mapping should be in the init module, to that before the loading of whick-key, otherwise it will not work
          local map = require('core.utils').map
          map("n", "<space>qs", [[<cmd>lua require("persistence").load()<cr>]])
          map("n", "<space>ql", [[<cmd>lua require("persistence").load({ last = true })<cr>]])
          map("n", "<space>qd", [[<cmd>lua require("persistence").stop()<cr>]])
        end,
        config = function()
          require("persistence").setup{
            dir = vim.fn.expand(vim.fn.stdpath("data") .. "/sessions/"),
            options = { "buffers", "curdir", "tabpages", "winsize" }
          }
        end,
      },
      {
        "folke/which-key.nvim",
        enabled = false,
        config = function()
          require("which-key").setup {}
        end
      },
      {
        "folke/todo-comments.nvim",
        enabled = true, -- just use treesitter comment instead, keep minimal
        event = 'BufRead',
        dependencies = "nvim-lua/plenary.nvim",
        config = function()
          -- HACK: #104 Invalid in command-line window
          local hl = require("todo-comments.highlight")
          local highlight_win = hl.highlight_win
          hl.highlight_win = function(win, force)
            pcall(highlight_win, win, force)
          end
          require("todo-comments").setup {
            keywords = {
              FIX = {
                icon = " ", -- icon used for the sign, and in search results
                color = "error", -- can be a hex color, or a named color (see below)
                alt = { "FIXME", "BUG", "FIXIT", "ISSUE", "MAYBE" }, -- a set of other keywords that all map to this FIX keywords
                signs = true, -- configure signs for some keywords individually
              },
            }
          }
          -- how to use it?
          -- using TODO: (the last colon is necessary)
        end
      },
      {
        'sindrets/diffview.nvim',
        cmd = 'DiffviewOpen',
        dependencies = 'nvim-lua/plenary.nvim',
      },
      {                                                                
        "nvim-pack/nvim-spectre",                                      
        -- NOTE: to make this work, you should have `gsed` in the $PATH `ln -s ~/.nix-profile/bin/sed ~/.local/bin/gsed`
        lazy = false,                                                  
        config = function ()                                           
          require("spectre").setup({ replace_engine = { sed = { cmd = "sed" } } })
          local map = require("core.utils").map                        
          map("n","<leader>S","<cmd>lua require('spectre').open()<CR>")
          map("n","<leader>sc","<cmd>lua require('spectre').open_file_search()<CR>")
          map("n","<leader>sw","<cmd>lua require('spectre').open_visual({select_word=true})<CR>")
          map("x","<leader>s","<cmd>lua require('spectre').open_visual()<CR>")
        end
      },
      {
        'brooth/far.vim',
        enabled = false,
        -- nvim-spectre is better
      },
      {
        't9md/vim-choosewin',
        event = "VimEnter",
        config = function ()
          vim.g.choosewin_overlay_enable = 1
          require('core.utils').map('n','-','<Plug>(choosewin)', {noremap=false})
        end
      },
      {
        "djoshea/vim-autoread",
        enabled = false,
      },
      {
        'alexghergh/nvim-tmux-navigation',
        event = 'VeryLazy',
        config = function()
          require'nvim-tmux-navigation'.setup {
            disable_when_zoomed = true, -- defaults to false
            keybindings = {
              left = "<C-LEFT>",
              down = "<C-DOWN>",
              up = "<C-UP>",
              right = "<C-RIGHT>",
              last_active = "<C-\\>",
              next = "<C-Space>",
            }
          }
        end
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
local specific_plugins = {}
local is_mac = vim.loop.os_uname().sysname=="Darwin"
if is_mac then
  specific_plugins = {
    { "kdheepak/cmp-latex-symbols"},
    {
      "lervag/vimtex",
      ft = 'tex',
      init = function()
        vim.g.vimtex_motion_enabled = 0
      end,
      config = function()
        vim.g.vimtex_view_method = "skim"
        vim.cmd([[
        let maplocalleader = ","
        ]])
      end,
    },
    {
      "rhysd/vim-grammarous",
      enabled = false, -- very hard to : cannot ignore the latex keywords
      init = function()
        vim.cmd([[
        let g:grammarous#languagetool_cmd = 'languagetool -l en-US'
        ]])
      end,
    },
  }
end
plugins = vim.list_extend(plugins,specific_plugins)
return plugins
