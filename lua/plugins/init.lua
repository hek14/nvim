vim.cmd[[packadd cfilter]]
local present, packer = pcall(require, "plugins.packerInit")

if not present then
  return false
end

local plugins = {
  { "nvim-lua/plenary.nvim" },

  { "lewis6991/impatient.nvim" },

  -- { "nathom/filetype.nvim" },

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
    after = {"nvim-web-devicons","nvim-treesitter","nvim-navic"},
    config = function ()
      require"plugins.configs.statusline".setup()
    end
  },

  {
    "akinsho/bufferline.nvim",
    branch = "main",
    after = { "nvim-web-devicons", "catppuccin" },
    config = "require('plugins.configs.bufferline')",
    setup = function()
      local map = require("core.utils").map
      map("n", {"<TAB>","]b"}, ":BufferLineCycleNext <CR>")
      map("n", {"<S-Tab>","[b"}, ":BufferLineCyclePrev <CR>")
    end,
  },

  {
    'romgrk/barbar.nvim',
    disable = true,
    after = 'nvim-web-devicons',
    requires = {'kyazdani42/nvim-web-devicons'},
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
      -- map('n', '[b', '<Cmd>BufferPrevious<CR>', opts)
      -- map('n', ']b', '<Cmd>BufferNext<CR>', opts)
    end
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    disable = false,
    event = "BufRead",
    config = function ()
      local default = {
        indentLine_enabled = 1,
        char = "▏",
        filetype_exclude = {
          "help",
          "terminal",
          "alpha",
          "packer",
          "lspinfo",
          "TelescopePrompt",
          "TelescopeResults",
          "lsp-installer",
          "",
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
    disable = true,
    config = function ()
      vim.cmd[[ colorscheme OceanicNext ]]
    end
  },

  {
    "bluz71/vim-nightfly-guicolors",
    disable = true,
    config = function ()
      vim.cmd [[colorscheme nightfly]]
    end
  },

  {
    "sainnhe/edge",
    disable = true,
    event = 'VimEnter',
    config = function ()
      vim.cmd [[ colorscheme edge ]]
    end
  },

  {
    "catppuccin/nvim", as = "catppuccin",
    event = 'BufRead',
    config = "require('plugins.configs.catppuccin')",
  },

  {
    "Mofiqul/vscode.nvim",
    disable = true,
    opt = false,
    config = function ()
      vim.o.background = 'dark'
      local c = require('vscode.colors')
      require('vscode').setup({
        -- Enable transparent background
        -- transparent = true,
        -- Enable italic comment
        italic_comments = true,
        -- Disable nvim-tree background color
        -- disable_nvimtree_bg = true,
        -- Override colors (see ./lua/vscode/colors.lua)
        -- color_overrides = {
        --   vscLineNumber = '#FFFFFF',
        -- },
        -- Override highlight groups (see ./lua/vscode/theme.lua)
        -- group_overrides = {
        --   -- this supports the same val table as vim.api.nvim_set_hl
        --   -- use colors from this colorscheme by requiring vscode.colors!
        --   Cursor = { fg=c.vscDarkBlue, bg=c.vscLightGreen, bold=true },
        --   StatusLine = { fg=c.vscDarkBlue, bg='#800020',italic=true }
        -- }
      })
    end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufRead", "BufNewFile" },
    module = "nvim-treesitter",
    config = "require('plugins.configs.treesitter')",
    run = ":TSUpdate",
  },
  { 
    "nvim-treesitter/nvim-treesitter-textobjects", 
    after = "nvim-treesitter"
  },
  { "nvim-treesitter/nvim-treesitter-refactor",
    after = "nvim-treesitter"
  },
  { 
    "p00f/nvim-ts-rainbow",
    after = "nvim-treesitter"
  },
  { 
    "theHamsta/nvim-treesitter-pairs",
    after = "nvim-treesitter"
  },
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
    disable = true,
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
    'kevinhwang91/nvim-ufo',
    disable = true,
    event = 'BufEnter',
    requires = 'kevinhwang91/promise-async',
    config = function ()
      local map = require("core.utils").map
      map('n', 'zR', require('ufo').openAllFolds)
      map('n', 'zM', require('ufo').closeAllFolds)
    end
  },
  -- git stuff
  {
    "lewis6991/gitsigns.nvim",
    event = 'BufRead',
    config = "require('plugins.configs.gitsigns')",
  },

  -- lsp stuff

  {
    "neovim/nvim-lspconfig",
    after = {"nvim-navic"},
    config = "require('plugins.configs.lspconfig')",
  },

  {
    'j-hui/fidget.nvim', -- show lsp progress
    config = function() require('fidget').setup {
      text = {
        -- spinner = 'line',
        spinner = 'dots',
        -- character shown when all tasks are complete
        done = "Done", -- f0e1e: 󰸞  (mdi-check-bold)
        commenced = "Started",    -- message shown when task starts
        completed = "Completed",  -- message shown when task completes
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
    disable = true,
    after = "nvim-lspconfig",
    config = function ()
      local present, lspsignature = pcall(require, "lsp_signature")
      if present then
        local default = {
          bind = true,
          doc_lines = 0,
          floating_window = true,
          fix_pos = true,
          hint_enable = true,
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
    end
  },

  {
    "williamboman/nvim-lsp-installer",
    module = "nvim-lsp-installer",
    cmd = {'LspInstall','LspUninstall','LspInstallInfo','LspUninstallAll'},
    config = function ()
      require("nvim-lsp-installer").setup {
        ensure_installed = {'pyright','sumneko_lua'}
      }
    end
  },
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
    "WhoIsSethDaniel/toggle-lsp-diagnostics.nvim",
    after = "nvim-lspconfig",
    config = function()
      vim.cmd([[command! -nargs=0 ToggleDiagVirtual lua require'toggle_lsp_diagnostics'.toggle_virtual_text()]])
    end,
  },
  {
    "SmiteshP/nvim-gps",
    disable = true, -- disable, in favour of SmiteshP/nvim-navic now
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
      require('core.utils').map("n", '[g', "<Cmd>lua require('contrib.gps_hack').gps_context_parent()<CR>", {silent=false})
    end,
  },
  {
    'hek14/nvim-navic', -- NOTE: after changing a repo to local, should 'PackerSync'
    after = { "nvim-treesitter", "nvim-web-devicons" },
    config = function ()
      require('core.utils').map("n", '[g', "<Cmd>lua require('nvim-navic').goto_last_context()<CR>", {silent=false})
    end
  },
  {
    "haringsrob/nvim_context_vt", -- another context plugin
    disable = true,
    after = "nvim-treesitter",
    event = "BufRead",
    config = "plugins.configs.nvim_context_vt"
  },

  {
    "folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons",
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
    disable = true,
    event = 'BufRead',
    setup = function()
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

  -- load luasnips + cmp related in insert mode only

  {
    "rafamadriz/friendly-snippets",
    module = "cmp_nvim_lsp",
    -- NOTE: can use regex pattern now
    -- module_pattern = {'cmp_nvim_lsp.*'}
    event = "InsertEnter",
  },

  {
    "hrsh7th/nvim-cmp",
    after = "friendly-snippets",
    config = "require('plugins.configs.cmp')"
  },

  {
    "L3MON4D3/LuaSnip",
    wants = "friendly-snippets",
    after = "nvim-cmp",
    config = "require('plugins.configs.luasnip')"
  },

  {
    "saadparwaiz1/cmp_luasnip",
    after = "LuaSnip",
  },

  {
    "hrsh7th/cmp-nvim-lua",
    after = "cmp_luasnip",
  },

  {
    "hrsh7th/cmp-nvim-lsp",
    after = "cmp-nvim-lua",
  },

  {
    "hrsh7th/cmp-buffer",
    after = "cmp-nvim-lsp",
  },

  {
    "hrsh7th/cmp-path",
    after = "cmp-buffer",
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
  -- misc plugins
  {
    "windwp/nvim-autopairs",
    after = "nvim-cmp",
    config = function ()
      local present1, autopairs = pcall(require, "nvim-autopairs")
      local present2, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")

      if present1 and present2 then
        local default = { fast_wrap = {} }
        autopairs.setup(default)
        local cmp = require "cmp"
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end
    end
  },

  {
    "goolord/alpha-nvim",
    config = function ()
      require"plugins.configs.alpha".setup()
    end
  },

  {
    "numToStr/Comment.nvim",
    module = "Comment",
    keys = { "gcc" },
    config = function ()
      local present, nvim_comment = pcall(require, "Comment")
      if present then
        local default = {}
        nvim_comment.setup(default)
      end
    end,
    setup = function()
      local map = require("core.utils").map
      map("n", "<leader>/", ":lua require('Comment.api').toggle.linewise.current()<CR>")
      map("v", "<leader>/", ":lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>")
    end,
  },

  -- file managing , picker etc
  {
    "kyazdani42/nvim-tree.lua",
    -- only set "after" if lazy load is disabled and vice versa for "cmd"
    after = "nvim-web-devicons",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    config = function ()
      require"plugins.configs.nvimtree".setup()
    end,
    setup = function()
      local map = require("core.utils").map
      map("n", "<leader>et", ":NvimTreeToggle <CR>")
      map("n", "<leader>ef", ":NvimTreeFocus <CR>")
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    -- module = "telescope", -- NOTE: don't use `module` and `cmd` at the same time: cause bug in Mac OS
    -- module_pattern = {'telescope.*'}
    opt = false, -- just load it once startup, this is core plugins
    config = "require('plugins.configs.telescope')",
    setup = function()
      local map = require("core.utils").map
      map("n", "<leader>fb", ":Telescope buffers <CR>")
      map("n", "<leader>ff", ":Telescope find_files find_command=rg,--ignore-file=" .. vim.env['HOME'] .. "/.rg_ignore," .. "--no-ignore,--files<CR>")
      map("n", "<leader>fa", ":Telescope find_files follow=true no_ignore=true hidden=true <CR>")
      map("n", "<leader>fg", ":Telescope git_commits <CR>")
      map("n", "<leader>gs", ":Telescope git_status <CR>")
      map("n", "<leader>fh", ":Telescope help_tags <CR>")
      map("n", "<leader>fo", ":Telescope oldfiles <CR>")
      map("n", "<leader>tm", ":Telescope themes <CR>")
      map("n", "<leader>fd", ":Telescope dotfiles <CR>")
      map("n", "<leader>rr", "<cmd>lua require('telescope.builtin').resume()<CR>")
      map("n",'<leader>fs','<Cmd>Telescope current_buffer_fuzzy_find fuzzy=false case_mode=ignore_case<CR>')
      -- if you want to grep only in opened buffers: lua require('telescope.builtin').live_grep({grep_open_files=true})
      -- pick a hidden term
      map("n", "<leader>T", ":Telescope terms <CR>")
      map("n", "<leader>f/", ":lua require('core.utils').grep_last_search()<CR>")
    end,
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
    'nvim-telescope/telescope-live-grep-args.nvim',
    config = function()
      require("core.utils").map('n','<leader>fw','<Cmd>lua require("telescope").extensions.live_grep_args.live_grep_args()<CR>')
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
  {
    "rrethy/vim-hexokinase",
    disable = true, -- NOTE: slow
    cond = function()
      return vim.fn.executable('go')==1
    end,
    run = "make hexokinase",
    event = "BufRead"
  },
  {
    "ahmedkhalf/project.nvim",
    config = require("plugins.configs.project").setup
  },
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
    opt = false,
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
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    setup = function()
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
  { "tpope/vim-scriptease" },
  { "MunifTanjim/nui.nvim" },
  {
    "danilamihailov/beacon.nvim",
    disable = true, -- disabled because of buggy on OSX
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
    "nvim-neotest/neotest",
    module = 'neotest',
    requires = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-plenary",
      "nvim-neotest/neotest-vim-test"
    },
    setup = function ()
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
    requires = { 
      { "skywind3000/asyncrun.vim", 
        cmd = 'AsyncRun',
        setup = function ()
          local ft_map = require("core.autocmds").ft_map
          ft_map('python','n',',t','<cmd>AsyncRun -cwd=$(VIM_FILEDIR) python "$(VIM_FILEPATH)"<CR>')
        end
      }},
    setup = function ()
      vim.g.asyncrun_open = 6
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
    disable = true,
    config = function()
      require("which-key").setup {}
    end
  },
  {
    "folke/todo-comments.nvim",
    disable = true, -- just use treesitter comment instead, keep minimal
    requires = "nvim-lua/plenary.nvim",
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
    "folke/lua-dev.nvim",
  },
  {
    'sindrets/diffview.nvim',
    cmd = 'DiffviewOpen',
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
    "djoshea/vim-autoread",
    disable = true,
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
    disable = true, -- feel slow
    requires = {
      {'ldelossa/litee-calltree.nvim',disable = true},
      {'ldelossa/litee-symboltree.nvim',disable = true},
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
    requires = { "kyazdani42/nvim-web-devicons" }, --optional
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
    { "kdheepak/cmp-latex-symbols", after = "nvim-cmp" },
    {
      "lervag/vimtex",
      setup = function()
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

local local_plugins = {
  ["hek14"] = true,
}
local function get_name(pkg)
  local parts = vim.split(pkg, "/")
  return parts[#parts], parts[1]
end

local function has_local(local_pkg)
  return vim.loop.fs_stat(vim.fn.expand(local_pkg)) ~= nil
end

local function process_local_plugins(spec)
  if type(spec) == "string" then
    local name, owner = get_name(spec)
    local local_pkg = vim.fn.stdpath("config") .. "/lua/contrib/" .. name

    if local_plugins[name] or local_plugins[owner] or local_plugins[owner .. "/" .. name] then
      if has_local(local_pkg) then
        return local_pkg
      else
        vim.notify("Local package " .. name .. " not found", vim.log.levels.ERROR, { title = 'Packer Starup' })
      end
    end
    return spec
  else
    for i, s in ipairs(spec) do
      spec[i] = process_local_plugins(s)
    end
  end
  if spec.requires then
    spec.requires = process_local_plugins(spec.requires)
  end
  return spec
end

local function wrap(use)
  return function(spec)
    spec = process_local_plugins(spec)
    use(spec)
  end
end

return packer.startup(function(use)
  local wrapped_use = wrap(use)
  for _, v in pairs(plugins) do
    wrapped_use(v)
  end
end)
