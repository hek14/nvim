vim.cmd[[packadd cfilter]]
local plugin_settings = require("core.utils").load_config().plugins
local present, packer = pcall(require, plugin_settings.options.packer.init_file)

if not present then
  return false
end

local plugins = {
  { "nvim-lua/plenary.nvim" },

  { "lewis6991/impatient.nvim" },

  { "nathom/filetype.nvim" },

  {
    "wbthomason/packer.nvim",
    -- NOTE: should not use this if you want to use packer functionality in shell with `--headless`
    -- event = "VimEnter", 
  },

  {
    "kyazdani42/nvim-web-devicons",
    config = function ()
      require("plugins.configs.icons").setup()
    end
  },

  {
    "feline-nvim/feline.nvim",
    disable = not plugin_settings.status.feline,
    after = {"nvim-web-devicons","nvim-treesitter","nvim-gps"},
    config = function ()
      require"plugins.configs.statusline".setup()
    end
  },

  {
    "akinsho/bufferline.nvim",
    branch = "main",
    disable = not plugin_settings.status.bufferline,
    after = "nvim-web-devicons",
    config = "require('plugins.configs.bufferline')",
    setup = function()
      require("core.mappings").bufferline()
    end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    disable = not plugin_settings.status.blankline,
    event = "BufRead",
    config = function ()
      require("plugins.configs.others").blankline()
    end
  },

  {
    "mhartington/oceanic-next",
    config = function ()
      vim.cmd[[ syntax enable ]] 
      vim.cmd[[ colorscheme OceanicNext ]]
    end
  },

  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufRead", "BufNewFile" },
    module = "nvim-treesitter",
    config = "require('plugins.configs.treesitter')",
    run = ":TSUpdate",
  },

  -- git stuff
  {
    "lewis6991/gitsigns.nvim",
    disable = not plugin_settings.status.gitsigns,
    opt = true,
    config = "require('plugins.configs.gitsigns')",
    setup = function()
      require("core.utils").packer_lazy_load "gitsigns.nvim"
    end,
  },

  -- lsp stuff

  {
    "neovim/nvim-lspconfig",
    module = "lspconfig",
    opt = true,
    setup = function()
      require("core.utils").packer_lazy_load "nvim-lspconfig"
      -- reload the current file so lsp actually starts for it
      vim.defer_fn(function()
        vim.cmd 'if &ft == "packer" | echo "" | else | silent! e %'
      end, 0)
    end,
    config = "require('plugins.configs.lspconfig')",
  },

  {
    "ray-x/lsp_signature.nvim",
    disable = not plugin_settings.status.lspsignature,
    after = "nvim-lspconfig",
    config = function ()
      require("plugins.configs.others").signature()
    end
  },

  { "williamboman/nvim-lsp-installer" },
  {
    "RishabhRD/nvim-lsputils",
    disable = true,
    -- deprecated: using my lsp handler and telescope.builtin.lsp
    requires = "RishabhRD/popfix",
    after = "nvim-lspconfig",
    config = function()
      require("plugins.configs.lsputil").setup()
    end
  },

  {
    "andymass/vim-matchup",
    disable = not plugin_settings.status.vim_matchup,
    opt = true,
    setup = function()
      vim.g.matchup_text_obj_enabled = 0
      vim.g.matchup_surround_enabled = 1
      require("core.utils").packer_lazy_load "vim-matchup"
    end,
  },

  {
    "max397574/better-escape.nvim",
    disable = not plugin_settings.status.better_escape,
    event = "InsertCharPre",
    config = function ()
      require"plugins.configs.others".better_escape()
    end
  },

  -- load luasnips + cmp related in insert mode only

  {
    "rafamadriz/friendly-snippets",
    module = "cmp_nvim_lsp",
    disable = not plugin_settings.status.cmp,
    event = "InsertEnter",
  },

  {
    "hrsh7th/nvim-cmp",
    after = "friendly-snippets",
    config = "require('plugins.configs.cmp')"
  },

  {
    "L3MON4D3/LuaSnip",
    disable = not plugin_settings.status.cmp,
    wants = "friendly-snippets",
    after = "nvim-cmp",
    config = "require('plugins.configs.luasnip')"
  },

  {
    "saadparwaiz1/cmp_luasnip",
    disable = not plugin_settings.status.cmp,
    after = plugin_settings.options.cmp.lazy_load and "LuaSnip",
  },

  {
    "hrsh7th/cmp-nvim-lua",
    disable = not plugin_settings.status.cmp,
    after = "cmp_luasnip",
  },

  {
    "hrsh7th/cmp-nvim-lsp",
    disable = not plugin_settings.status.cmp,
    after = "cmp-nvim-lua",
  },

  {
    "hrsh7th/cmp-buffer",
    disable = not plugin_settings.status.cmp,
    after = "cmp-nvim-lsp",
  },

  {
    "hrsh7th/cmp-path",
    disable = not plugin_settings.status.cmp,
    after = "cmp-buffer",
  },

  -- misc plugins
  {
    "windwp/nvim-autopairs",
    disable = not plugin_settings.status.autopairs,
    after = plugin_settings.options.autopairs.loadAfter,
    config = function ()
      require"plugins.configs.others".autopairs()
    end
  },

  {
    disable = not plugin_settings.status.alpha,
    "goolord/alpha-nvim",
    config = function ()
      require"plugins.configs.alpha".setup()
    end
  },

  {
    "numToStr/Comment.nvim",
    disable = not plugin_settings.status.comment,
    module = "Comment",
    keys = { "gcc" },
    config = function ()
      require"plugins.configs.others".comment()
    end,
    setup = function()
      require("core.mappings").comment()
    end,
  },

  -- file managing , picker etc
  {
    "kyazdani42/nvim-tree.lua",
    disable = not plugin_settings.status.nvimtree,
    -- only set "after" if lazy load is disabled and vice versa for "cmd"
    after = not plugin_settings.options.nvimtree.lazy_load and "nvim-web-devicons",
    cmd = plugin_settings.options.nvimtree.lazy_load and { "NvimTreeToggle", "NvimTreeFocus" },
    config = function ()
      require"plugins.configs.nvimtree".setup()
    end,
    setup = function()
      require("core.mappings").nvimtree()
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    module = "telescope",
    cmd = "Telescope",
    config = "require('plugins.configs.telescope')",
    setup = function()
      require("core.mappings").telescope()
    end,
  },

  {
    "RRethy/vim-illuminate", 
    event = "BufRead"
  },
  {
    "rrethy/vim-hexokinase",
    cond = function()
      return vim.fn.executable('go')==1
    end,
    run = "make hexokinase",
    event = "BufRead"
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    -- providing extra formatting and linting
    -- NullLsInfo to show what's now enabled
    -- Remember: you should install formatters/linters in $PATH, null-ls will not do this for you.
    -- if other formatting method is enabled by the lspconfig(pyright for example), then you should turn that of in the on_attach function like below:
    -- function on_attach(client,bufnr)
    --    if client.name = "pyright" then
    --         client.resolved_capabilities.document_formatting = false
    --    end
    -- end
    after = "nvim-lspconfig",
    config = function()
      local formatting = require("null-ls").builtins.formatting
      local diagnostics = require("null-ls").builtins.diagnostics
      local code_actions = require("null-ls").builtins.code_actions
      require("null-ls").setup({
        sources = {
          formatting.lua_format.with({ extra_args = {"--indent-width=4"}}),
          formatting.black.with({ extra_args = {"--fast" }}),
          code_actions.gitsigns,
        },

        -- format on save
        -- on_attach = function(client)
        --   if client.resolved_capabilities.document_formatting then
        --       vim.cmd "autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()"
        --   end
        -- end
      })
    end,
  },
  {
    "folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require("trouble").setup({})
    end,
  },
  { "ahmedkhalf/project.nvim", config = require("plugins.configs.project").setup },
  {
    "tmhedberg/SimpylFold",
    disable = true,
    -- using treesitter fold now
    config = function()
      vim.g.SimpylFold_docstring_preview = 1
    end,
  },
  {
    "mfussenegger/nvim-dap",
    after = "telescope.nvim",
    requires = {
      "nvim-telescope/telescope-dap.nvim",
      "theHamsta/nvim-dap-virtual-text",
      "mfussenegger/nvim-dap-python",
      "rcarriga/nvim-dap-ui",
    },
    config = "require('plugins.configs.dap')"
  },
  {
    "sakhnik/nvim-gdb",
    setup = function()
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
    setup = function()
      require("core.utils").map("n", "gq", "<cmd>TZFocus<CR>")
      require("core.utils").map("i", "<C-q>", "<cmd>TZFocus<CR>")
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
  {
    "hrsh7th/cmp-cmdline",
    after = "cmp-nvim-lua",
    config = function()
      local cmp = require("cmp")
      cmp.setup.cmdline("/", { sources = { { name = "buffer" } } })

      --  cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(":", {
        sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
      })
    end,
  }, -- enhance grep and quickfix list
  {
    "lukas-reineke/cmp-rg",
    after = "cmp-nvim-lua"
  },
  {
    "hrsh7th/cmp-nvim-lsp-signature-help",
    after = "cmp-nvim-lua"
  },
  -- 1. populate the quickfix
  {
    "mhinz/vim-grepper",
    config = function()
      vim.g.grepper =
        {
          tools = { "rg", "grep" },
          searchreg = 1,
          next_tool = "<leader>gw",
        }, vim.cmd([[
          nnoremap <leader>gw :Grepper<cr>
          nmap <leader>gs  <plug>(GrepperOperator)
          xmap <leader>gs  <plug>(GrepperOperator)
      ]])
    end,
  }, 
  -- 2. setup better qf buffer
  {
    "kevinhwang91/nvim-bqf",
    disable = true,
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
    disable = true,
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
    "WhoIsSethDaniel/toggle-lsp-diagnostics.nvim",
    after = "nvim-lspconfig",
    config = function()
      vim.cmd([[command! -nargs=0 ToggleDiagVirtual lua require'toggle_lsp_diagnostics'.toggle_virtual_text()]])
    end,
  },
  {
    'VonHeikemen/searchbox.nvim',
    disable = true, -- NOTE: can't resume previous/next search history
    requires = {
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
    "SmiteshP/nvim-gps",
    -- this plugin shows the code context in the statusline: check ~/.config/nvim/lua/plugins/configs/statusline.lua
    after = { "nvim-treesitter", "nvim-web-devicons" },
    wants = { "nvim-treesitter" }, -- loader treesitter if necessary
    config = function()
      -- nvim-treesitter should be loaded now
      -- print('wants treesitter',packer_plugins["nvim-treesitter"].loaded) 
      require("nvim-gps").setup({
        disable_icons = false, -- Setting it to true will disable all icons
        icons = {
          ["class-name"] = " ", -- Classes and class-like objects
          ["function-name"] = " ", -- Functions
          ["method-name"] = " ", -- Methods (functions inside class-like objects)
          ["container-name"] = " ", -- Containers (example: lua tables)
          ["tag-name"] = "炙", -- Tags (example: html tags)
        },
      })
    end,
  },
  {
    "haringsrob/nvim_context_vt", -- another context plugin
    disable = true,
    after = "nvim-treesitter",
    event = "BufRead",
    config = "plugins.configs.nvim_context_vt"
  },

  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    setup = function()
      require("core.utils").map("n", "<C-x>u", ":UndotreeToggle | UndotreeFocus<CR>")
    end,
  },
  { "nvim-treesitter/nvim-treesitter-textobjects", after = "nvim-treesitter" },
  { "nvim-treesitter/nvim-treesitter-refactor",
    after = "nvim-treesitter" 
  }, 
  { "p00f/nvim-ts-rainbow", after = "nvim-treesitter" },
  { "theHamsta/nvim-treesitter-pairs", after = "nvim-treesitter" },
  {
    "ThePrimeagen/refactoring.nvim",
    -- disable = true, -- unstable and buggy
    after = "nvim-treesitter",
    requires = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" },
    },
    config = function()
      require("refactoring").setup({})
      local map = require("core.utils").map
      map("v", "<leader>re", [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Function')<CR>]], {noremap = true, silent = true, expr = false})
      map("v", "<leader>rf", [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Function To File')<CR>]], {noremap = true, silent = true, expr = false})
      map("v", "<leader>rv", [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Variable')<CR>]], {noremap = true, silent = true, expr = false})
      map("v", "<leader>ri", [[ <Esc><Cmd>lua require('refactoring').refactor('Inline Variable')<CR>]], {noremap = true, silent = true, expr = false})
      map("n", "<leader>ri", [[ <Cmd>lua require('refactoring').refactor('Inline Variable')<CR>]], {noremap = true, silent = true, expr = false})
      map("n", "<leader>rb", [[ <Cmd>lua require('refactoring').refactor('Extract Block')<CR>]], {noremap = true, silent = true, expr = false})
      map("n", "<leader>rbf", [[ <Cmd>lua require('refactoring').refactor('Extract Block To File')<CR>]], {noremap = true, silent = true, expr = false})
    end,
  },
  { 
    "nvim-treesitter/playground",
    after = "nvim-treesitter",
    config = function ()
      require('core.utils').map('n',',x',':TSPlaygroundToggle<cr>')
      require('core.utils').map('n',',h',':TSHighlightCapturesUnderCursor<cr>')
    end
  },
  {
    "David-Kunz/treesitter-unit",
    after = "nvim-treesitter",
    config = function ()
      require"treesitter-unit".enable_highlighting()
      local map = require("core.utils").map
      map("x","uu",":lua require'treesitter-unit'.select()<CR>",{noremap=true})
      map("x","au",":lua require'treesitter-unit'.select(true)<CR>",{noremap=true})
      map("o","uu","<Cmd>lua require'treesitter-unit'.select()<CR>",{noremap=true})
      map("o","au","<Cmd>lua require'treesitter-unit'.select(true)<CR>",{noremap=true})
    end
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
  {
    "akinsho/toggleterm.nvim",
    -- use floaterm instead
    disable = true,
    config = "require('plugins.configs.toggleterm')",
  },
  {
    "voldikss/vim-floaterm",
    opt = false,
    config = "require('plugins.configs.floaterm')"
  },
  {
    -- after = 'telescope.nvim', -- do not lazy load telescope extensions, will ca bugs: module not found
    "dhruvmanila/telescope-bookmarks.nvim", -- this plugin is for searching browser bookmarks
  },
  {
    'ThePrimeagen/harpoon',
    module = "harpoon"
  },
  {
    'nvim-telescope/telescope-live-grep-raw.nvim',
    config = function()
      require("core.utils").map('n','<leader>fw','<Cmd>lua require("telescope").extensions.live_grep_raw.live_grep_raw()<CR>')
    end
  },
  {
    "AckslD/nvim-neoclip.lua",
    -- after = 'telescope.nvim', -- do not lazy load telescope extensions, will ca bugs: module not found
    config = function()
      require("neoclip").setup()
      vim.cmd([[inoremap <C-p> <cmd>Telescope neoclip<CR>]])
    end,
  },
  {
    "tversteeg/registers.nvim"
  },
  {
    "jvgrootveld/telescope-zoxide",
    setup = function()
      require("core.utils").map("n", "<leader>z", ":Telescope zoxide list<CR>")
    end,
    config = function()
      require("telescope._extensions.zoxide.config").setup({
        mappings = {
          ["<C-b>"] = {
            keepinsert = true,
            action = function(selection)
              require("telescope").extensions.file_browser.file_browser({ cwd = selection.path })
              -- vim.cmd('Telescope file_browser path=' .. selection.path)
            end,
          },
        },
      })
    end,
  },
  { "nvim-telescope/telescope-file-browser.nvim" },
  { "tpope/vim-scriptease" },
  { "MunifTanjim/nui.nvim" },
  { 
    "danilamihailov/beacon.nvim",
    disable = true, -- disabled because of buggy on OSX
  },
  {
    "rcarriga/nvim-notify",
    config = function()
      vim.notify = require("notify")
    end,
  },
  {
    "iamcco/markdown-preview.nvim",
    run = function()
      vim.fn["mkdp#util#install"](0)
    end,
    setup = function()
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
    disable = true,
    run = 'bash ./install.sh'
  },
  {
    "metakirby5/codi.vim",
    setup = function()
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
    "rcarriga/vim-ultest", 
    requires = {"vim-test/vim-test"},
    run = function ()
      local dependencies = {"pynvim","pytest"}
      for _,dep in ipairs(dependencies) do
        local result = vim.fn.system("pip list | grep -i " .. dep) 
        local found = #result>0
        if not found then
          local Job = require'plenary.job'
          Job:new({
            command = 'pip',
            args = { 'install','--user',dep},
            cwd = vim.fn.getcwd(),
            on_stderr = function ()
              vim.schedule_wrap(function ()
                print(string.format("error happened when installing %s, please install %s!"),dep,dep)
                print("vim-ultest failed to setup")
              end)
            end,
            on_exit = function(j, return_val)
              vim.schedule_wrap(function()
                if dep=="pytest" then
                  vim.cmd[[UpdateRemotePlugins]]
                end
              end)
            end,
          }):sync() -- or start()
        end
      end
    end,
    config = function ()
      require("ultest").setup{
        builders = {
          ['python#pytest'] = function(cmd)
            -- The command can start with python command directly or an env manager
            local non_modules = {'python', 'pipenv', 'poetry'}
            -- Index of the python module to run the test.
            local module_index = 1
            if vim.tbl_contains(non_modules, cmd[1]) then
              module_index = 3
            end
            local module = cmd[module_index]

            -- Remaining elements are arguments to the module
            local args = vim.list_slice(cmd, module_index + 1)
            return {
              dap = {
                type = 'python',
                request = 'launch',
                module = module,
                args = args
              }
            }
          end
        }
      }
    end
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    module = "persistence",
    setup = function ()
      -- this mapping should be in the setup module, to that before the loading of whick-key, otherwise it will not work
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
    config = function()
      require("which-key").setup {}
    end
  },
  {
    "folke/todo-comments.nvim",
    requires = "nvim-lua/plenary.nvim",
    config = function()
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
    "folke/lua-dev.nvim",
  },
  { 
    'sindrets/diffview.nvim', 
    requires = 'nvim-lua/plenary.nvim',
  },
  {
    "nvim-pack/nvim-spectre",
    requires = {'nvim-lua/plenary.nvim','kyazdani42/nvim-web-devicons'},
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
    disable = true,
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
  }
}

local specific_plugins = {}
local is_mac = vim.loop.os_uname().sysname=="Darwin"
if is_mac then
  specific_plugins = {
    { "kdheepak/cmp-latex-symbols", after = "nvim-cmp" },
    {
      "lervag/vimtex",
      config = function()
        vim.g.vimtex_view_method = "skim"
        vim.cmd([[
          let maplocalleader = ","
        ]])
      end,
    },
    {
      "rhysd/vim-grammarous",
      disable = true, -- very hard to : cannot ignore the latex keywords
      setup = function()
        vim.cmd([[
          let g:grammarous#languagetool_cmd = 'languagetool -l en-US'
        ]])
      end,
    },
  }
end

plugins = vim.list_extend(plugins,specific_plugins)

return packer.startup(function(use)
  for _, v in pairs(plugins) do
    use(v)
  end
end)
