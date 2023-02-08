local map = require("core.utils").map
local M = {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    {
      "dhruvmanila/telescope-bookmarks.nvim", -- this plugin is for searching browser bookmarks
    },
    {
      'nvim-telescope/telescope-live-grep-args.nvim',
      config = function()
        -- require("core.utils").map('n','<leader>fw','<Cmd>lua require("telescope").extensions.live_grep_args.live_grep_args()<CR>')
      end
    },
    {
      "AckslD/nvim-neoclip.lua",
      dependencies = {
        "kkharji/sqlite.lua"
      },
      config = function()
        require('telescope').load_extension('neoclip')
        require("neoclip").setup({
          enable_persistent_history = true,
          default_register = '+',
          keys = {
            telescope = {
              i = {
                select = '<CR>',
                paste = '<C-P>',
                paste_behind = '<C-B>',
                replay = '<C-Q>',
                delete = '<C-D>',
                custom = {},
              },
              n = {
                select = '<CR>',
                paste = 'p',
                paste_behind = 'P',
                replay = 'q',
                edit = '<C-e>',
                delete = 'd',
                custom = {},
              }
            }}
          })
          local map = require("core.utils").map
          map("i","<C-x><C-p>","<cmd>lua require('telescope').extensions.neoclip.default()<CR>")
        end,
      },
      {
        "jvgrootveld/telescope-zoxide",
        init = function()
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
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
    },
  lazy = false,
  init = function()
    map("n", "<leader>b", ":Telescope buffers <CR>")
    map("n", "<leader>ff",
      ":Telescope find_files find_command=rg,--ignore-file=" ..
      vim.env['HOME'] .. "/.rg_ignore," .. "--no-ignore,--files<CR>")
    map("n", "<leader>fa", ":Telescope find_files follow=true no_ignore=true hidden=true <CR>")
    map("n", "<leader>fg", ":Telescope git_commits <CR>")
    map("n", "<leader>gs", ":Telescope git_status <CR>")
    map("n", "<leader>fh", ":Telescope help_tags <CR>")
    map("n", "<leader>fo", ":Telescope oldfiles <CR>")
    map("n", "<leader>fd", ":Telescope dotfiles <CR>")
    map("n", "<leader>fr", "<cmd>lua require('telescope.builtin').resume()<CR>")
    map("n", '<leader>fs', '<Cmd>Telescope current_buffer_fuzzy_find fuzzy=false case_mode=ignore_case<CR>')
    -- if you want to grep only in opened buffers: lua require('telescope.builtin').live_grep({grep_open_files=true})
    -- pick a hidden term
    map("n", "<leader>f/", ":lua require('core.utils').grep_last_search()<CR>")
  end,
}

function M.config()
  local custom_pickers = require 'contrib.telescope_custom_pickers'
  map("n", "<leader>fw", custom_pickers.live_grep)
  local telescope = require "telescope"
  local fixfolds = {
    hidden = true,
    attach_mappings = function(_)
      require("telescope.actions.set").select:enhance({
        post = function() vim.cmd [[normal! zx]] end
      })
      return true
    end
  }

  local options = {
    pickers = {
      buffers = fixfolds,
      file_browser = fixfolds,
      find_files = fixfolds,
      git_files = fixfolds,
      grep_string = fixfolds,
      live_grep = {
        mappings = {
          i = {
            ['<c-f>'] = custom_pickers.actions.set_extension,
            ['<c-l>'] = custom_pickers.actions.set_folders,
          },
        },
      },
      oldfiles = fixfolds,
      lsp_definitions = fixfolds,
      lsp_references = fixfolds,
      lsp_document_symbols = fixfolds,
      lsp_workspace_symbols = fixfolds,
      lsp_dynamic_workspace_symbols = fixfolds
    },
    defaults = {
      mappings = {
        i = {
          ["<cr>"] = function(prompt_bufnr)
            require('telescope.actions').select_default(prompt_bufnr)
            -- vim.cmd[[normal! zv]]
            vim.cmd [[echom "telescope hello"]]
          end
        },
        n = {
          ["n"] = require('telescope.actions').move_selection_next,
          ["e"] = require('telescope.actions').move_selection_previous,
        }
      },
      vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "--no-ignore",
        "--ignore-file=" .. vim.env["HOME"] .. "/.rg_ignore"
      },
      file_ignore_patterns = {
        ".git",
        "__pycache__",
        "%.log",
        "%.npz",
        "%.npy",
        "%.pkl",
        "%.png",
        "%.jpg",
        "node_modules"
      },
      prompt_prefix = "   ",
      selection_caret = "  ",
      entry_prefix = "  ",
      initial_mode = "insert",
      selection_strategy = "reset",
      sorting_strategy = "ascending",
      layout_strategy = "horizontal",
      layout_config = {
        horizontal = {
          prompt_position = "top",
          preview_width = 0.55,
          results_width = 0.8
        },
        vertical = { mirror = false },
        width = 0.87,
        height = 0.80,
        preview_cutoff = 120
      },
      file_sorter = require("telescope.sorters").get_fuzzy_file,
      generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
      path_display = { "truncate" },
      winblend = 0,
      border = {},
      borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
      color_devicons = true,
      use_less = true,
      set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
      file_previewer = require("telescope.previewers").vim_buffer_cat.new,
      grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
      qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
      -- Developer configurations: Not meant for general override
      buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker
    },
    extensions = {
      bookmarks = {
        -- Available: 'brave', 'chrome', 'edge', 'firefox', 'safari'
        selected_browser = 'chrome'
      },
      fzf = {
        fuzzy = true, -- false will only do exact matching
        override_generic_sorter = true, -- override the generic sorter
        override_file_sorter = true, -- override the file sorter
        case_mode = "smart_case", -- or "ignore_case" or "respect_case"
        -- the default case_mode is "smart_case"
      }
    },
  }

  telescope.setup(options)

  local extensions = {
    "bookmarks", "projects", "zoxide", "file_browser", "dotfiles", "live_grep_args", "fzf"
  }
  for _, ext in ipairs(extensions) do telescope.load_extension(ext) end
end

return M
