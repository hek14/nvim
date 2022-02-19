local custom_plugins = {
  { "williamboman/nvim-lsp-installer" },
  {
    "RishabhRD/nvim-lsputils",
    disable = true,
    requires = "RishabhRD/popfix",
    after = "nvim-lspconfig",
    config = require("custom.pluginConfs.lsputils").setup,
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    -- providing extra formatting and linting
    -- NullLsInfo to show what's now d
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
          formatting.lua_format,
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
    config = function()
      vim.g.SimpylFold_docstring_preview = 1
    end,
  },
  {
    "mfussenegger/nvim-dap",
    disable = false,
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
    "blackCauldron7/surround.nvim",
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
  }, -- 2. setup better qf buffer
  {
    "kevinhwang91/nvim-bqf",
    config = function()
      -- need this to  with quickfix-reflector
      vim.cmd([[
        augroup nvim-bqf-kk
          autocmd FileType qf lua vim.defer_fn(function() require('bqf').enable() end,50)
          augroup END
        ]])
    end,
  }, -- 3. editable qf (similar to emacs wgrep)
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
    config = function()
      if not packer_plugins["nvim-treesitter"].loaded then
        print("treesitter not ready")
        packer_plugins["nvim-treesitter"].loaded = true
        require("packer").loader("nvim-treesitter")
      end
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
    config = function()
      require("core.utils").map("n", "<C-x>u", ":UndotreeToggle | UndotreeFocus<CR>")
    end,
  },
  { "nvim-treesitter/nvim-treesitter-textobjects", after = "nvim-treesitter" },
  { "nvim-treesitter/nvim-treesitter-refactor", after = "nvim-treesitter" },
  { "p00f/nvim-ts-rainbow", after = "nvim-treesitter" },
  { "theHamsta/nvim-treesitter-pairs", after = "nvim-treesitter" },
  {
    "ThePrimeagen/refactoring.nvim",
    after = "nvim-treesitter",
    requires = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" },
    },
    config = function()
      require("refactoring").setup({})
      -- Remaps for each of the four debug operations currently offered by the plugin
      vim.api.nvim_set_keymap(
        "v",
        "<Leader>re",
        [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Function')<CR>]],
        {
          noremap = true,
          silent = true,
          expr = false,
        }
      )
      vim.api.nvim_set_keymap(
        "v",
        "<Leader>rf",
        [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Function To File')<CR>]],
        {
          noremap = true,
          silent = true,
          expr = false,
        }
      )
      vim.api.nvim_set_keymap(
        "v",
        "<Leader>rv",
        [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Variable')<CR>]],
        {
          noremap = true,
          silent = true,
          expr = false,
        }
      )
      vim.api.nvim_set_keymap(
        "v",
        "<Leader>ri",
        [[ <Esc><Cmd>lua require('refactoring').refactor('Inline Variable')<CR>]],
        {
          noremap = true,
          silent = true,
          expr = false,
        }
      )
    end,
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
    "dhruvmanila/telescope-bookmarks.nvim",
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
  {
    disable = true, -- just  simple nui
    "ray-x/guihua.lua",
    run = "cd lua/fzy && make",
  },
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
