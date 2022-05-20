-- IMPORTANT NOTE : This is default config, so dont change anything here.
-- use custom/chadrc.lua instead

local M = {}

local os_name = vim.loop.os_uname().sysname
_G.is_mac = os_name == 'Darwin'
_G.is_linux = os_name == 'Linux'
_G.is_windows = os_name == 'Windows'
_G.diagnostic_choice = "telescope" -- telescope or Trouble

local clippy_found = vim.fn.executable("clippy")==1

M.options = {
   clipboard = clippy_found and "unnamedplus" or "",
   cmdheight = 1,
   ruler = false,
   hidden = true,
   ignorecase = true,
   smartcase = true,
   mapleader = " ",
   mouse = "a",
   number = true,
   numberwidth = 2,
   relativenumber = false,
   expandtab = true,
   shiftwidth = 2,
   smartindent = true,
   tabstop = 8,
   timeoutlen = 400,
   updatetime = 250,
   undofile = true,
   fillchars = { eob = " " },
   shadafile = vim.opt.shadafile,
   terminal = {
      behavior = {
         close_on_exit = true,
      },
      window = {
         vsplit_ratio = 0.5,
         split_ratio = 0.4,
      },
      location = {
         horizontal = "rightbelow",
         vertical = "rightbelow",
         float = {
           relative = 'editor',
           row = 0.3,
           col = 0.25,
           width = 0.5,
           height = 0.4,
           border = "single",
         }
      },
   },
}

---- UI -----

M.ui = {
   hl_override = "", -- path of your file that contains highlights
   italic_comments = false,
   theme = "onedark", -- default theme
   transparency = false,
}

---- PLUGIN OPTIONS ----

M.plugins = {

   -- builtin nvim plugins are disabled
   builtins = {
      "2html_plugin",
      "getscript",
      "getscriptPlugin",
      "gzip",
      "logipat",
      "netrw",
      "netrwPlugin",
      "netrwSettings",
      "netrwFileHandlers",
      "matchit",
      "tar",
      "tarPlugin",
      "rrhelper",
      "spellfile_plugin",
      "vimball",
      "vimballPlugin",
      "zip",
      "zipPlugin",
   },

   -- enable/disable plugins (false for disable)
   status = {
      vim_matchup = false,
      dashboard = true,
      lspsignature = false, -- replace with hrsh7th/cmp-nvim-lsp-signature-help
      feline = true,
      alpha = true,
      blankline = true, -- indentline stuff
      bufferline = true, -- manage and preview opened buffers
      colorizer = false, -- color RGB, HEX, CSS, NAME color codes
      comment = true, -- easily (un)comment code, language aware
      better_escape = true, -- map to <ESC> with no lag
      gitsigns = true,
      cmp = true,
      nvimtree = true,
      autopairs = true,
   },
   options = {
      packer = {
         init_file = "plugins.packerInit",
      },
      autopairs = { loadAfter = "nvim-cmp" },
      cmp = {
         lazy_load = true,
      },
      lspconfig = {
         setup_lspconf = "custom.pluginConfs.lspconfig", -- path of file containing setups of different lsps
      },
      nvimtree = {
         -- packerCompile required after changing lazy_load
         lazy_load = true,
      },
      luasnip = {
         snippet_path = {},
      },
      statusline = {
         hide_disable = false,
         -- hide, show on specific filetypes
         hidden = {
            "help",
            "NvimTree",
            "terminal",
            "alpha",
         },
         shown = {},

         -- truncate statusline on small screens
         shortline = true,
         style = "default", -- default, round , slant , block , arrow
      },
      esc_insertmode_timeout = 300,
   },
}

-- Don't use a single keymap twice

--- MAPPINGS ----

-- non plugin
M.mappings = {
   -- custom = {}, -- custom user mappings

   misc = {
      cheatsheet = "<leader>ch",
      close_buffer = "<leader>x",
      cp_whole_file = "<C-c>", -- copy all contents of current buffer
      lineNR_toggle = "<leader>n", -- toggle line number
      lineNR_rel_toggle = "<leader>rn",
      new_buffer = "<S-t>",
      new_tab = "<C-t>b",
      save_file = "<C-s>", -- save file using :w
   },

   -- navigation in insert mode, only if enabled in options

   insert_nav = {
      forward = "<C-f>",
      backward = "<C-b>",
      next_line = "<C-n>",
      prev_line = "<C-p>",
      beginning_of_line = "<C-a>",
      end_of_line = "<C-e>",
   },

   -- better window movement
   window_nav = {
      moveLeft = "<C-h>",
      moveDown = "<C-n>",
      moveRight = "<C-i>",
      moveUp = "<C-e>",
   },

   -- terminal related mappings
   terminal = {
      -- multiple mappings can be given for esc_termmode, esc_hide_termmode

      -- get out of terminal mode
      esc_termmode = { "jj" },

      -- get out of terminal mode and hide it
      esc_hide_termmode = { "J" },
      -- show & recover hidden terminal buffers in a telescope picker
      pick_term = "<leader>T",

      -- spawn a single terminal and toggle it
      -- this just works like toggleterm kinda
      new_horizontal = "<leader>h",
      new_vertical = "<leader>v",
      new_float = "<A-i>",

      -- spawn new terminals
      spawn_horizontal = "<A-h>",
      spawn_vertical = "<A-v>",
      spawn_window = "<leader>w",
   },
}

-- plugins related mappings
-- To disable a mapping, equate the variable to "" or false or nil in chadrc
M.mappings.plugins = {
   bufferline = {
      next_buffer = {"<TAB>","]b"},
      prev_buffer = {"<S-Tab>","[b"},
   },
   comment = {
      toggle = "<leader>/",
   },

   -- map to <ESC> with no lag
   better_escape = { -- <ESC> will still work
      esc_insertmode = { "jk" }, -- multiple mappings allowed
   },

   lspconfig = {
      declaration = "gD",
      definition = "gd",
      hover = "K",
      implementation = "gi",
      signature_help = "gk",
      add_workspace_folder = "<leader>wa",
      remove_workspace_folder = "<leader>wr",
      list_workspace_folders = "<leader>wl",
      type_definition = "<leader>D",
      rename = "<leader>ra",
      code_action = "<leader>ca",
      references = "gr",
      float_diagnostics = "ge",
      goto_prev = "[d",
      goto_next = "]d",
      set_loclist = "<leader>q",
      formatting = "<leader>fm",
   },

   nvimtree = {
      toggle = "<C-n>",
      focus = "<leader>e",
   },

   telescope = {
      buffers = "<leader>fb",
      find_files = "<leader>ff",
      find_hiddenfiles = "<leader>fa",
      git_commits = "<leader>cm",
      git_status = "<leader>gt",
      help_tags = "<leader>fh",
      live_grep = {},
      oldfiles = "<leader>fo",
   },
}

return M
