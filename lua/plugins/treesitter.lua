local M = {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "BufReadPost",
    dependencies = {
        {"nvim-treesitter/nvim-treesitter-textobjects"},
        {"nvim-treesitter/nvim-treesitter-refactor"}, {"p00f/nvim-ts-rainbow"},
        {"theHamsta/nvim-treesitter-pairs"}, {
            "ThePrimeagen/refactoring.nvim",
            enabled = false, -- unstable and buggy
            dependencies = {
                {"nvim-lua/plenary.nvim"}, {"nvim-treesitter/nvim-treesitter"}
            },
            config = function()
                require("refactoring").setup({})
                local map = require("core.utils").map
                map("v", "<leader>re",
                    [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Function')<CR>]],
                    {noremap = true, silent = true, expr = false})
                map("v", "<leader>rf",
                    [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Function To File')<CR>]],
                    {noremap = true, silent = true, expr = false})
                map("v", "<leader>rv",
                    [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Variable')<CR>]],
                    {noremap = true, silent = true, expr = false})
                map("v", "<leader>ri",
                    [[ <Esc><Cmd>lua require('refactoring').refactor('Inline Variable')<CR>]],
                    {noremap = true, silent = true, expr = false})
                map("n", "<leader>ri",
                    [[ <Cmd>lua require('refactoring').refactor('Inline Variable')<CR>]],
                    {noremap = true, silent = true, expr = false})
                map("n", "<leader>rb",
                    [[ <Cmd>lua require('refactoring').refactor('Extract Block')<CR>]],
                    {noremap = true, silent = true, expr = false})
                map("n", "<leader>rbf",
                    [[ <Cmd>lua require('refactoring').refactor('Extract Block To File')<CR>]],
                    {noremap = true, silent = true, expr = false})
            end
        }, {
            "nvim-treesitter/playground",
            config = function()
                require('core.utils').map('n', ',x', ':TSPlaygroundToggle<cr>')
                require('core.utils').map('n', ',h',
                                          ':TSHighlightCapturesUnderCursor<cr>')
            end
        }, {
            "David-Kunz/treesitter-unit",
            enabled = false,
            config = function()
                require"treesitter-unit".enable_highlighting()
                local map = require("core.utils").map
                map("x", "uu", ":lua require'treesitter-unit'.select()<CR>",
                    {noremap = true})
                map("x", "au", ":lua require'treesitter-unit'.select(true)<CR>",
                    {noremap = true})
                map("o", "uu", "<Cmd>lua require'treesitter-unit'.select()<CR>",
                    {noremap = true})
                map("o", "au",
                    "<Cmd>lua require'treesitter-unit'.select(true)<CR>",
                    {noremap = true})
            end
        }
    }
}

function M.config()
    ts_config = require "nvim-treesitter.configs"
    ts_config.setup {
        highlight = {enable = true, use_languagetree = true},
        indent = {enable = false},
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = "<leader>vn",
                node_incremental = "gnn",
                scope_incremental = "gne",
                node_decremental = "gee"
            }
        },
        rainbow = {
            enable = true,
            -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
            extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
            max_file_lines = nil -- Do not enable for files with more than n lines, int
            -- colors = {}, -- table of hex strings
            -- termcolors = {} -- table of colour name strings
        },
        pairs = {
            enable = true,
            disable = {},
            highlight_pair_events = {}, -- e.g. {"CursorMoved"}, -- when to highlight the pairs, use {} to deactivate highlighting
            highlight_self = false, -- whether to highlight also the part of the pair under cursor (or only the partner)
            goto_right_end = false, -- whether to go to the end of the right partner or the beginning
            keymaps = {goto_partner = "%", delete_balanced = "X"},
            delete_balanced = {
                only_on_first_char = false, -- whether to trigger balanced delete when on first character of a pair
                fallback_cmd_normal = nil, -- fallback command when no pair found, can be nil
                longest_partner = false -- whether to delete the longest or the shortest pair when multiple found.
                -- E.g. whether to delete the angle bracket or whole tag in  <pair> </pair>
            }
        },
        -- refactor = {
        --   highlight_definitions = { enable = true },
        --   highlight_current_scope = { enable = true },
        --   smart_rename = {
        --     enable = true,
        --     keymaps = {
        --       smart_rename = "<leader>R",
        --     },
        --   },
        --   navigation = {
        --     enable = true,
        --   },
        -- },
        textobjects = {
            select = {
                enable = true,

                -- Automatically jump forward to textobj, similar to targets.vim
                lookahead = true,

                keymaps = {
                    -- You can use the capture groups defined in textobjects.scm
                    ["af"] = "@function.outer",
                    ["uf"] = "@function.inner",
                    ["ac"] = "@class.outer",
                    ["uc"] = "@class.inner",
                    ["aa"] = "@parameter.outer",
                    ["ua"] = "@parameter.inner"
                }
            },
            swap = {
                enable = true,
                swap_next = {["<leader>a"] = "@parameter.inner"},
                swap_previous = {["<leader>A"] = "@parameter.inner"}
            },
            move = {
                enable = true,
                set_jumps = true, -- whether to set jumps in the jumplist
                goto_next_start = {
                    ["]m"] = "@function.outer",
                    ["]c"] = "@class.outer",
                    ["]a"] = "@parameter.inner"
                },
                goto_next_end = {
                    ["]M"] = "@function.outer",
                    ["]["] = "@class.outer",
                    ["]A"] = "@parameter.inner"
                },
                goto_previous_start = {
                    ["[m"] = "@function.outer",
                    ["[c"] = "@class.outer",
                    ["[a"] = "@parameter.inner"
                },
                goto_previous_end = {
                    ["[M"] = "@function.outer",
                    ["[]"] = "@class.outer",
                    ["[A"] = "@parameter.inner"
                }
            }
        }
    }
    vim.cmd [[
          highlight def KK_init guibg=grey guifg=blue gui=italic
          highlight def TSDefinitionUsage guibg=#444444 " NOTE: highlight used in treesitter-refactor
          highlight def Visual guibg=#6c6c6c
          " " for GUI nvim(iTerm,kitty,etc.):
          " highlight Search gui=italic guibg=peru guifg=wheat
          " " for terminal nvim:
          " highlight Search cterm=NONE ctermfg=grey ctermbg=blue
          " " def a highlight by linking
          " highlight def link Search Todo
          ]]
    -- require"nvim-treesitter.highlight".set_custom_captures {
    --   ["init_func"] = "KK_init",
    -- }
    vim.api.nvim_set_hl(0, "@init_func.python", {link = "KK_init"})
    vim.cmd [[
                set foldmethod=expr
                set foldexpr=nvim_treesitter#foldexpr()
                ]]
end
return M
