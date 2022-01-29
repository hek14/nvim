-- IMPORTANT NOTE : This is the user config, can be edited. Will be preserved if updated with internal updater
-- This file is for NvChad options & tools, custom settings are split between here and 'lua/custom/init.lua'

local M = {}
M.options, M.ui, M.mappings, M.plugins = {}, {}, {}, {}

-- NOTE: To use this, make a copy with `cp example_chadrc.lua chadrc.lua`

--------------------------------------------------------------------

-- To use this file, copy the structure of `core/default_config.lua`,
-- examples of setting relative number & changing theme:

local global_env = require('custom.utils').global_env
M.options = {
   relativenumber = false,
   clipboard = global_env.is_mac and "unnamedplus" or "",
}

-- M.ui = {
--   theme = "nord"
-- }

-- NvChad included plugin options & overrides


M.plugins = {
  status = {
    vim_matchup = false,
    dashboard = true,
    lspsignature = true,
    feline = true,
  },
 options = {
   lspconfig = {
     -- path of file containing setups of different lsps (ex : "custom.plugins.lspconfig"), read the docs for more info
     setup_lspconf = "custom.plugins.lspconfig",
   },
   luasnip = {
     snippet_path = {}
   }
 },
  -- To change the Packer `config` of a plugin that comes with NvChad,
  -- add a table entry below matching the plugin github name
  --              '-' -> '_', remove any '.lua', '.nvim' extensions
  -- this string will be called in a `require`
  --              use "(custom.configs).my_func()" to call a function
  --              use "custom.blankline" to call a file
  default_plugin_config_replace = {
    bufferline="custom/plugins/bufferline",
    nvim_cmp="custom/plugins/cmp",
    gitsigns="custom/plugins/gitsigns",
    nvim_treesitter='custom/plugins/treesitter',
    luasnip="custom/plugins/luasnip",
    telescope="custom/plugins/telescope",
  },
}

M.mappings = {
  terminal = {
    esc_termmode = { "jj" }, -- multiple mappings allowed
    -- get out of terminal mode and hide it
    esc_hide_termmode = { "J" }, -- multiple mappings allowed
    pick_term ="<space>T",
    new_horizontal = {},
    new_window = {},
    new_vertical = {},
  },
  insert_nav = {
    beginning_of_line = "<C-a>",
    end_of_line = "<C-e>",
    backward = "<C-h>",
    prev_line = "<C-n>",
    next_line = "<C-e>",
    forward = "<C-i>",
  },
  --better window movement
  window_nav = {
    moveLeft = "<C-h>",
    moveRight = "<C-l>",
    moveUp = "<C-k>",
    moveDown = "<C-j>",
  },
  plugins = {
    bufferline = {
      next_buffer = {"]b","<TAB>"},
      prev_buffer = {"[b","<S-Tab>"}
    }
  }
}

return M
