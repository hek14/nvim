-- IMPORTANT NOTE : This is the user config, can be edited. Will be preserved if updated with internal updater
-- This file is for NvChad options & tools, custom settings are split between here and 'lua/custom/init.lua'

local M = {}
M.options, M.ui, M.mappings, M.plugins = {}, {}, {}, {}

-- NOTE: To use this, make a copy with `cp example_chadrc.lua chadrc.lua`

--------------------------------------------------------------------

-- To use this file, copy the structure of `core/default_config.lua`,
-- examples of setting relative number & changing theme:

-- M.options = {
--    relativenumber = true,
-- }

-- M.ui = {
--   theme = "nord"
-- }

-- NvChad included plugin options & overrides
M.plugins = {
  status = {
    vim_matchup = true,
    dashboard = true,
    lspsignature = false,
  },
 options = {
   lspconfig = {
     -- path of file containing setups of different lsps (ex : "custom.plugins.lspconfig"), read the docs for more info
     setup_lspconf = "custom.plugins.lspconfig",
   },
 },
  -- To change the Packer `config` of a plugin that comes with NvChad,
  -- add a table entry below matching the plugin github name
  --              '-' -> '_', remove any '.lua', '.nvim' extensions
  -- this string will be called in a `require`
  --              use "(custom.configs).my_func()" to call a function
  --              use "custom.blankline" to call a file
  default_plugin_config_replace = {},
}

M.mappings = {
  terminal = {
    esc_termmode = { "jj" }, -- multiple mappings allowed
    -- get out of terminal mode and hide it
    esc_hide_termmode = { "J" }, -- multiple mappings allowed
    new_horizontal = "<leader>tt",
    new_window = "<leader>tw",
    new_vertical = "<leader>tv",
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
}

return M