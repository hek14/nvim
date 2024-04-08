local map = require("core.utils").map
local M = {
  "nvim-telescope/telescope.nvim",
  enabled = true,
  cmd = "Telescope",
  keys = {
    { "<leader>b", "<cmd>Telescope buffers<CR>" },
    -- { "<leader>ff", "<cmd>Telescope find_files find_command=rg,--ignore-file=" .. vim.env['HOME'] .. "/.rg_ignore," .. "--no-ignore,--files<CR>" },
    { "<leader>ff", "<cmd>Telescope find_files<CR>" },
    { "<leader>fa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>" },
    { "<leader>fg", "<cmd>Telescope git_commits<CR>" },
    { "<leader>gs", "<cmd>Telescope git_status<CR>" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>" },
    { "<leader>fo", "<cmd>Telescope oldfiles<CR>" },
    { "<leader>fd", "<cmd>Telescope dotfiles<CR>" },
    { "<leader>fr", "<cmd>lua require('telescope.builtin').resume()<CR>" },
    { "<leader>fk", "<cmd>lua require('telescope.builtin').keymaps()<CR>" },
    { '<leader>/', '<Cmd>Telescope current_buffer_fuzzy_find fuzzy=false case_mode=ignore_case<CR>' },
    -- if you want to grep only in opened buffers<cmd> lua require('telescope.builtin').live_grep({grep_open_files=true})
    { "<leader>fw", "<Cmd>Telescope live_grep_args<CR>"},
    { "<leader>f/", "<cmd>lua require('core.utils').grep_last_search()<CR>" },
    { "<leader><space>", "<cmd>Telescope commands<CR>" },
    -- { "<leader><leader>w", "<Cmd>lua require('telescope.builtin').grep_string()<CR>"},
    { "<leader>z", ":Telescope zoxide list<CR>" },
    -- { "<leader>sd", function ()
    --   require('telescope.builtin').live_grep({
    --     cwd = '/usr/local/share/nvim/runtime/doc/'
    --   })
    -- end },
    { ",l", require('scratch.telescope_list_sections').list_section }
  },
  dependencies = {
    {
      "nvim-telescope/telescope-smart-history.nvim",
      dependencies = {
        "kkharji/sqlite.lua"
      }
    },
    {
      "dhruvmanila/telescope-bookmarks.nvim", -- this plugin is for searching browser bookmarks
      config = function()
        require('browser_bookmarks').setup({
          selected_browser = "chrome"
        })
      end
    },
    {
      'nvim-telescope/telescope-live-grep-args.nvim',
      config = function()
        -- map('n','<leader>fw','<Cmd>lua require("telescope").extensions.live_grep_args.live_grep_args()<CR>')
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
          map("i","<C-x><C-p>","<cmd>lua require('telescope').extensions.neoclip.default()<CR>")
        end,
      },
      { "jvgrootveld/telescope-zoxide" },
      { "nvim-telescope/telescope-file-browser.nvim" },
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      { 'IllustratedMan-code/telescope-conda.nvim' }
    },
}

local open_in_nvim_tree = function(prompt_bufnr)
    local Path = require "plenary.path"

    local entry = require('telescope.actions.state').get_selected_entry()[1]
    local entry_path = Path:new(entry):parent():absolute()
    require('telescope.actions')._close(prompt_bufnr, true)
    entry_path = Path:new(entry):parent():absolute() 
    entry_path = entry_path:gsub("\\", "\\\\")

    vim.cmd("NvimTreeClose")
    vim.cmd("NvimTreeOpen " .. entry_path)

    local file_name = nil
    for s in string.gmatch(entry, "[^/]+") do
        file_name = s
    end

    vim.cmd("/" .. file_name)
end

function M.config()
  local custom_pickers = require 'contrib.telescope_custom_pickers'
  local telescope = require "telescope"
  local action_state = require("telescope.actions.state")
  local actions = require("telescope.actions")
  actions.insert_name_i = function(prompt_bufnr)
    local symbol = action_state.get_selected_entry().ordinal
    actions.close(prompt_bufnr)
    vim.schedule(function()
      vim.cmd([[startinsert]])
      vim.api.nvim_put({ symbol }, "", true, true)
    end)
  end
  actions.insert_name_and_path_i = function(prompt_bufnr)
    local symbol = action_state.get_selected_entry().value
    actions.close(prompt_bufnr)
    vim.schedule(function()
      vim.cmd([[startinsert]])
      vim.api.nvim_put({ symbol }, "", true, true)
    end)
  end
  local fixfolds = {
    hidden = false,
    attach_mappings = function(_)
      require("telescope.actions.set").select:enhance({
        post = function() vim.cmd [[normal! zx]] end
      })
      return true
    end
  }

  local options = {
    pickers = {
      buffers = {
        ignore_current_buffer = true,
        sort_lastused = true,
      },
      live_grep = {
        mappings = {
          i = {
            ['<c-f>'] = custom_pickers.actions.set_extension,
            ['<c-l>'] = custom_pickers.actions.set_folders,
          },
        },
      },
    },
    defaults = {
      -- layout_strategy = vim.loop.os_uname().sysname=='Linux' and 'vertical' or 'horizontal',
      layout_strategy = 'horizontal',
      layout_config = { height = 0.8 },
      history = {
        path = '~/.local/share/nvim/databases/telescope_history.sqlite3',
        limit = 100,
      },
      mappings = {
        i = {
          ["<C-n>"] = actions.cycle_history_next,
          ["<C-p>"] = actions.cycle_history_prev,
          ["<cr>"] = function(prompt_bufnr)
            require('telescope.actions').select_default(prompt_bufnr)
            local val = action_state.get_current_line()
            vim.schedule(function()
              vim.fn.setreg('p',val)
              -- vim.cmd[[normal! zv]]
            end)
          end,
          ["<c-s>"] = open_in_nvim_tree,
        },
        n = {
          ["n"] = require('telescope.actions').move_selection_next,
          ["e"] = require('telescope.actions').move_selection_previous,
          ["<c-s>"] = open_in_nvim_tree,
          ["<esc>"] = function(prompt_bufnr)
            require('telescope.actions').close(prompt_bufnr)
            local val = action_state.get_current_line()
            vim.schedule(function()
              vim.fn.setreg('p',val)
            end)
          end,
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
        -- "--ignore-file=" .. vim.env["HOME"] .. "/.rg_ignore"
        -- --no_ignore will search too much files, you can toggle this option in live_grep_args
      },
      file_ignore_patterns = {
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
      selection_caret = '  ',
      entry_prefix = '   ',
      initial_mode = "insert",
      path_display = { "truncate" },
      winblend = 0,
      color_devicons = true,
      set_env = { ["COLORTERM"] = "truecolor" },
    },
    extensions = {
      fzf = {
        fuzzy = true, -- false will only do exact matching
        override_generic_sorter = true, -- override the generic sorter
        override_file_sorter = true, -- override the file sorter
        case_mode = "smart_case", -- or "ignore_case" or "respect_case"
        -- the default case_mode is "smart_case"
      },
      zoxide = {
        mappings = {
          ["<C-b>"] = {
            keepinsert = true,
            action = function(selection)
              require("telescope").extensions.file_browser.file_browser({ cwd = selection.path })
              -- vim.cmd('Telescope file_browser path=' .. selection.path)
            end,
          },
        },
      }
    },
  }

  -- options.defaults = require('telescope.themes').get_ivy(options.defaults)
  telescope.setup(options)
  local extensions = {
    "bookmarks", "zoxide", "file_browser", "dotfiles", "live_grep_args", "fzf","conda", "smart_history"
  }
  for _, ext in ipairs(extensions) do telescope.load_extension(ext) end
end

return M
