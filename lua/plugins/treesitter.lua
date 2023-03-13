local M = {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  init = function ()
    local group = vim.api.nvim_create_augroup('load_treesitter',{clear=true})
    vim.api.nvim_create_autocmd('BufRead',{ callback = function ()
      if package.loaded['nvim-treesitter'] then
        vim.schedule(function ()
          vim.api.nvim_clear_autocmds({group='load_treesitter'})
        end)
      end
      local bufnr = vim.api.nvim_get_current_buf()
      if vim.api.nvim_buf_line_count(bufnr) <= 3000 and not package.loaded['nvim-treesitter'] then
        require('nvim-treesitter')
        vim.schedule(function ()
          vim.cmd[[TSBufEnable all]] -- for the first buffer
          vim.api.nvim_clear_autocmds({group='load_treesitter'})
        end)
      end
    end,
    group = group
  })
  end,
  dependencies = {
    {"nvim-treesitter/nvim-treesitter-textobjects"},
    {"nvim-treesitter/nvim-treesitter-refactor"}, {"p00f/nvim-ts-rainbow"},
    {"theHamsta/nvim-treesitter-pairs"},
    {
      "nvim-treesitter/playground",
      config = function()
        require('core.utils').map('n', ',x', ':TSPlaygroundToggle<cr>')
        require('core.utils').map('n', ',h',':TSHighlightCapturesUnderCursor<cr>')
      end
    }, 
    {
      "David-Kunz/treesitter-unit",
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
  local options = {
    ensure_installed = {"python","c","query","vim","markdown"}, -- NOTE: playground need query parser
    playground = { 
      enable = true 
    },
    query_linter = {
      enable = true,
      use_virtual_text = true,
      lint_events = { "BufWrite", "CursorHold" },
    },
    highlight = {
      enable = true, 
      use_languagetree = true,
    },
    indent = {
      enable = false
    },
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
          ["]f"] = "@function.outer",
          ["]]"] = "@class.outer",
          ["]a"] = "@parameter.inner"
        },
        goto_next_end = {
          ["]F"] = "@function.outer",
          ["]["] = "@class.outer",
          ["]A"] = "@parameter.inner"
        },
        goto_previous_start = {
          ["[f"] = "@function.outer",
          ["[["] = "@class.outer",
          ["[a"] = "@parameter.inner"
        },
        goto_previous_end = {
          ["[F"] = "@function.outer",
          ["[]"] = "@class.outer",
          ["[A"] = "@parameter.inner"
        }
      }
    }
  }
  for k,v in pairs(options) do
    if k~='ensure_installed' then
      v.disable = function(lang,bufnr)
        return vim.api.nvim_buf_line_count(bufnr) > 3000
      end
    end
  end
  require "nvim-treesitter.configs".setup(options)
  vim.api.nvim_set_hl(0,'TSDefinitionUsage',{
    fg = 'blue', bg = '#444444', italic = true,
  })
  vim.api.nvim_set_hl(0,'TSDefinitionUsage',{
    fg = 'blue', bg = '#444444', italic = true,
  })
  vim.api.nvim_set_hl(0, "@init_func.python", {link = "KK_init"})
  vim.api.nvim_set_hl(0,'KK_init',{
    fg = 'blue', bg = 'grey', italic = true,
  })
end
return M
