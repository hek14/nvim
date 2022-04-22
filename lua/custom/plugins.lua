local custom_plugins = {
  { "williamboman/nvim-lsp-installer" },
  {
    "RishabhRD/nvim-lsputils",
    disable = true,
    -- deprecated: using my lsp handler and telescope.builtin.lsp
    requires = "RishabhRD/popfix",
    after = "nvim-lspconfig",
    config = require("custom.pluginConfs.lsputils").setup,
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
          formatting.lua_format.with({ extra_args = {"--indent-width=2"}}),
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
  { "ahmedkhalf/project.nvim", config = require("custom.pluginConfs.project").setup },
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
    config = function()
      require("custom.pluginConfs.dap")
    end,
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
    after = "cmp-buffer",
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
    -- deprecated: using myself custom.utils.preview_qf()
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
    -- deprecated: using myself custom.utils.preview_qf()
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
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    setup = function()
      require("core.utils").map("n", "<C-x>u", ":UndotreeToggle | UndotreeFocus<CR>")
    end,
  },
  { "nvim-treesitter/nvim-treesitter-textobjects", after = "nvim-treesitter" },
  { "nvim-treesitter/nvim-treesitter-refactor", after = "nvim-treesitter" },
  { "p00f/nvim-ts-rainbow", after = "nvim-treesitter" },
  { "theHamsta/nvim-treesitter-pairs", after = "nvim-treesitter" },
  {
    "ThePrimeagen/refactoring.nvim",
    disable = true, -- unstable and buggy
    after = "nvim-treesitter",
    requires = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" },
    },
    config = function()
      require("refactoring").setup({})
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
    disable = true,
    -- use floaterm instead
    config = function()
      require("custom.pluginConfs.toggleterm")
    end,
  },
  {
    "voldikss/vim-floaterm",
    opt = false,
    config = function()
      require("custom.pluginConfs.floaterm")
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
  { "danilamihailov/beacon.nvim" },
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
      require('core.utils').map('n','-','<Plug>(choosewin)', {noremap=False})
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

custom_plugins = vim.list_extend(custom_plugins,specific_plugins)
-- for _,v in ipairs(specific_plugins) do
--   custom_plugins[#custom_plugins+1] = v
-- end
return custom_plugins
