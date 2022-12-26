local plugins = {
  { "nvim-lua/plenary.nvim" },
  { "nvim-tree/nvim-web-devicons" },
  {
    'romgrk/barbar.nvim',
    enabled = false,
    config = function ()
      require'bufferline'.setup {
        icons = false,
      }
      local map = vim.api.nvim_set_keymap
      local opts = { noremap = true, silent = true }
      map('n', '<leader>1', '<Cmd>BufferGoto 1<CR>', opts)
      map('n', '<leader>2', '<Cmd>BufferGoto 2<CR>', opts)
      map('n', '<leader>3', '<Cmd>BufferGoto 3<CR>', opts)
      map('n', '<leader>4', '<Cmd>BufferGoto 4<CR>', opts)
      map('n', '<leader>5', '<Cmd>BufferGoto 5<CR>', opts)
      map('n', '<leader>6', '<Cmd>BufferGoto 6<CR>', opts)
      map('n', '<leader>7', '<Cmd>BufferGoto 7<CR>', opts)
      map('n', '<leader>8', '<Cmd>BufferGoto 8<CR>', opts)
      map('n', '<leader>9', '<Cmd>BufferGoto 9<CR>', opts)
      map('n', '<leader>0', '<Cmd>BufferLast<CR>', opts)
      map('n', '[b', '<Cmd>BufferPrevious<CR>', opts)
      map('n', ']b', '<Cmd>BufferNext<CR>', opts)
    end
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufRead",
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
    "mhartington/oceanic-next",
    enabled = false,
    config = function ()
      vim.cmd[[ colorscheme OceanicNext ]]
    end
  },
  {
    "bluz71/vim-nightfly-guicolors",
    enabled = false,
    config = function ()
      vim.cmd [[colorscheme nightfly]]
    end
  },
  {
    "sainnhe/edge",
    enabled = false,
    event = 'VimEnter',
    config = function ()
      vim.cmd [[ colorscheme edge ]]
    end
  },
  {
    "Mofiqul/vscode.nvim",
    enabled = false,
    lazy = false,
    config = function ()
      vim.o.background = 'dark'
      local c = require('vscode.colors')
      require('vscode').setup({
        italic_comments = true,
      })
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
    'j-hui/fidget.nvim', -- show lsp progress
    config = function() require('fidget').setup {
      text = {
        spinner = 'dots', -- or 'line'
        done = "Done",
        commenced = "Started",
        completed = "Completed",
      },
      window = {
        blend = 0,  -- &winblend for the window
      },
      fmt = {
        stack_upwards = true,  -- list of tasks grows upwards
      }
    } end
  },
  {
    "ray-x/lsp_signature.nvim",
    enabled = false,
    config = function ()
      local default = {
        bind = true,
        doc_lines = 0,
        floating_window = true,
        fix_pos = true,
        hint_enabled = true,
        hint_prefix = " ",
        hint_scheme = "String",
        hi_parameter = "Search",
        max_height = 22,
        max_width = 120, -- max_width of signature floating_window, line will be wrapped if exceed max_width
        handler_opts = {
          border = "single", -- double, single, shadow, none
        },
        zindex = 200, -- by default it will be on top of all floating windows, set to 50 send it to bottom
        padding = "", -- character to pad on left and right of signature can be ' ', or '|'  etc
      }
      lspsignature.setup(default)
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
    "WhoIsSethDaniel/toggle-lsp-diagnostics.nvim",
    init = function()
      vim.cmd([[command! -nargs=0 ToggleDiagVirtual lua require'toggle_lsp_diagnostics'.toggle_virtual_text()]])
    end,
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
    config = function ()
      vim.g.Illuminate_delay = 17
    end,
    event = "BufRead"
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
  },
  {
    "tversteeg/registers.nvim"
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
    "hekq/surround.nvim.bak",
    event = "BufEnter",
    config = function()
      require("surround").setup({ mappings_style = "surround" })
    end,
  },
  {
    "ggandor/lightspeed.nvim",
    event = "VimEnter",
    config = function()
      require("lightspeed").setup({})
    end,
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
    },
    {
      "stevearc/dressing.nvim",
      event = "VimEnter",
      config = function()
        require("dressing").setup({})
      end,
    },
    { "tpope/vim-scriptease", lazy=false },
    { "MunifTanjim/nui.nvim" },
    {
      "danilamihailov/beacon.nvim",
      enabled = false, -- disabled because of buggy on OSX
    },
    {
      "rcarriga/nvim-notify",
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
        "skywind3000/asynctasks.vim",
        cmd = 'AsyncTask',
        dependencies = { 
          { "skywind3000/asyncrun.vim", 
          cmd = 'AsyncRun',
          init = function ()
            local ft_map = require("core.autocmds").ft_map
            ft_map('python','n',',t','<cmd>AsyncRun -cwd=$(VIM_FILEDIR) python "$(VIM_FILEPATH)"<CR>')
          end
        }},
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
        enabled = false, -- just use treesitter comment instead, keep minimal
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
        config = function ()
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
        "preservim/vimux",
      },
      {
        'alexghergh/nvim-tmux-navigation',
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
        branch = "main",
        config = function()
          local ok, cybu = pcall(require, "cybu")
          if not ok then
            return
          end
          cybu.setup()
          vim.keymap.set("n", "<leader>n", "<Plug>(CybuNext)",{})
          vim.keymap.set("n", "<leader>e", "<Plug>(CybuPrev)",{})
        end,
      },
      {
        "habamax/vim-winlayout",
        config = function()
          vim.keymap.set("n", ",,", "<Plug>(WinlayoutBackward)",{})
          vim.keymap.set("n", ",.", "<Plug>(WinlayoutBackward)",{})
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
