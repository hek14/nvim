-- IMPORTANT NOTE : This is the user config, can be edited. Will be preserved if updated with internal updater
-- This file is for NvChad options & tools, custom settings are split between here and 'lua/custom/init.lua'

local M = {}
M.options, M.ui, M.mappings, M.plugins = {}, {}, {}, {}

-- NOTE: To use this, make a copy with `cp example_chadrc.lua chadrc.lua`

--------------------------------------------------------------------

-- To use this file, copy the structure of `core/default_config.lua`,
-- examples of setting relative number & changing theme:

local os_name = vim.loop.os_uname().sysname
_G.is_mac = os_name == 'Darwin'
_G.is_linux = os_name == 'Linux'
_G.is_windows = os_name == 'Windows'
_G.diagnostic_choice = "telescope" -- telescope or Trouble

M.options = {
   relativenumber = false,
   clipboard = is_mac and "unnamedplus" or "",
}

M.ui = {
  theme = "kanagawa",
}

-- NvChad included plugin options & overrides

local customPlugins = require('custom.plugins')

M.plugins = {
  install = customPlugins,
  status = {
    vim_matchup = false,
    dashboard = true,
    lspsignature = false, -- replace with hrsh7th/cmp-nvim-lsp-signature-help
    feline = true,
    alpha = true,
  },
 options = {
   lspconfig = {
     -- path of file containing setups of different lsps (ex : "custom.pluginConfs.lspconfig"), read the docs for more info
     setup_lspconf = "custom.pluginConfs.lspconfig",
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
    bufferline="custom/pluginConfs/bufferline",
    nvim_cmp="custom/pluginConfs/cmp",
    gitsigns="custom/pluginConfs/gitsigns",
    nvim_treesitter='custom/pluginConfs/treesitter',
    luasnip="custom/pluginConfs/luasnip",
    telescope="custom/pluginConfs/telescope",
  },
}

M.mappings = {
  misc = {
      copy_whole_file = {}, -- copy all contents of current buffer
      copy_to_system_clipboard = {}, -- copy selected text (visual mode) or curent line (normal)
  },
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
    end_of_line = {},
    backward = {},
    prev_line = {},
    next_line = {},
    forward = {},
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
