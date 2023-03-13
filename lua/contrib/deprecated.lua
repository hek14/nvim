local plugins = {
  {
    'AckslD/messages.nvim',
    enabled = false,
    cmd = 'Messages',
    init = function ()
      msg = function(...)
        require('messages.api').capture_thing(...)
      end
    end,
    config = function ()
      require("messages").setup()
    end
  },
  { 
    "glepnir/whiskyline.nvim",
    enabled = false,
    event = "VeryLazy",
    config = function ()
      require("whiskyline").setup()
    end
  },
  {
    "tversteeg/registers.nvim",
    enabled = false,
  },
  {
    "ray-x/lsp_signature.nvim",
    enabled = false,
    config = function ()
      local default = {
        bind = true,
        doc_lines = 0,
        floating_window = true,
        fix_pos = true,
        hint_enabled = true,
        hint_prefix = " ",
        hint_scheme = "String",
        hi_parameter = "Search",
        max_height = 22,
        max_width = 120, -- max_width of signature floating_window, line will be wrapped if exceed max_width
        handler_opts = {
          border = "single", -- double, single, shadow, none
        },
        zindex = 200, -- by default it will be on top of all floating windows, set to 50 send it to bottom
        padding = "", -- character to pad on left and right of signature can be ' ', or '|'  etc
      }
      require("lspsignature").setup(default)
    end
  },
  {
    "andymass/vim-matchup",
    enabled = false,
    event = 'BufRead',
    init = function()
      vim.g.matchup_text_obj_enabled = 0
      vim.g.matchup_surround_enabled = 1
    end,
  },
  { 
    'michaelb/sniprun',
    enabled = false,
    build = 'bash ./install.sh'
  },
  {
    "kylechui/nvim-surround",
    enabled = false,
    event = "BufEnter",
    config = function()
      require("nvim-surround").setup()
    end,
  },
  {
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
  },
  {
    'kevinhwang91/nvim-ufo',
    enabled = false,
    event = 'BufEnter',
    dependencies = 'kevinhwang91/promise-async',
    config = function ()
      local map = require("core.utils").map
      map('n', 'zR', require('ufo').openAllFolds)
      map('n', 'zM', require('ufo').closeAllFolds)
    end
  },
  {
    'romgrk/barbar.nvim',
    enabled = false,
    event = 'VeryLazy',
    config = function ()
      require'bufferline'.setup({
        icons = 'numbers'
      })
      local map = require("core.utils").map
      map('n', '<leader>1', '<Cmd>BufferGoto 1<CR>')
      map('n', '<leader>2', '<Cmd>BufferGoto 2<CR>')
      map('n', '<leader>4', '<Cmd>BufferGoto 4<CR>')
      map('n', '<leader>5', '<Cmd>BufferGoto 5<CR>')
      map('n', '<leader>6', '<Cmd>BufferGoto 6<CR>')
      map('n', '<leader>7', '<Cmd>BufferGoto 7<CR>')
      map('n', '<leader>8', '<Cmd>BufferGoto 8<CR>')
      map('n', '<leader>9', '<Cmd>BufferGoto 9<CR>')
      map('n', '<leader>0', '<Cmd>BufferLast<CR>')
      map('n', '[b', '<Cmd>BufferPrevious<CR>')
      map('n', ']b', '<Cmd>BufferNext<CR>')
    end
  },
  {
    "rrethy/vim-hexokinase",
    enabled = false, -- NOTE: slow
    cond = function()
      return vim.fn.executable('go')==1
    end,
    build = "make hexokinase",
    event = "BufRead"
  },
  {
    "tmhedberg/SimpylFold",
    enabled = false,
    config = function()
      vim.g.SimpylFold_docstring_preview = 1
    end,
  },
  {
    "ronakg/quickr-preview.vim",
    enabled = false,
    -- deprecated: using myself core.utils.preview_qf()
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
    'VonHeikemen/searchbox.nvim',
    enabled = false, -- NOTE: can't resume previous/next search history
    dependencies = {
      {'MunifTanjim/nui.nvim'}
    },
    config = function ()
      require("core.utils").map('n','/',":lua require('searchbox').match_all()<CR>")
      require("core.utils").map('x','/',"<Esc>:lua require('searchbox').match_all({visual_mode = true})<CR>")
      require("core.utils").map('n','?',":lua require('searchbox').match_all({reverse=true})<CR>")
      require("core.utils").map('x','?',"<Esc>:lua require('searchbox').match_all({visual_mode = true,reverse = true})<CR>")
    end
  },
  {
    "stevearc/dressing.nvim",
    enabled = false,
    event = "VimEnter",
    config = function()
      require("dressing").setup({})
    end,
  },
  {
    "folke/noice.nvim",
    enabled = false, -- currently very unstable
    event = 'VimEnter',
    config = function()
      require("noice").setup({
        lsp = {
          hover = {
            enabled = false
          },
          signature = {
            enabled = false
          }
        },
      })
    end,
    requires = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    }
  },
  {
    "danilamihailov/beacon.nvim",
    enabled = false, -- disabled because of buggy on OSX
  },
  {
    "folke/which-key.nvim",
    enabled = false,
    config = function()
      require("which-key").setup {}
    end
  },
  {
    "djoshea/vim-autoread",
    enabled = false,
  },
  {
    'ldelossa/litee.nvim',
    enabled = false, -- feel slow
    dependencies = {
      {'ldelossa/litee-calltree.nvim',enabled = false},
      {'ldelossa/litee-symboltree.nvim',enabled = false},
    },
    config = function()
      require('litee.lib').setup({})
      require('litee.calltree').setup({})
      require('litee.symboltree').setup({})
    end
  },
  {
    "ghillb/cybu.nvim",
    enabled = false,
    lazy = false,
    config = function()
      local ok, cybu = pcall(require, "cybu")
      if not ok then
        return
      end
      cybu.setup()
      require('core.utils').map("n", "<leader>n", "<Plug>(CybuNext)",{})
      require('core.utils').map("n", "<leader>e", "<Plug>(CybuPrev)",{})
    end,
  },
  {
    "habamax/vim-winlayout",
    lazy = false,
    enabled = false,
    config = function()
      require('core.utils').map("n", ",,", "<Plug>(WinlayoutBackward)",{})
      require('core.utils').map("n", "..", "<Plug>(WinlayoutForward)",{})
    end
  },
  {
    'brooth/far.vim',
    enabled = false,
    -- nvim-spectre is better
  },
}

--<<< feline.nvim
local M = {
  "feline-nvim/feline.nvim",
  enabled = false,
  dependencies = { "hek14/nvim-navic","hek14/vim-illuminate" },
  event = "VeryLazy"
}

M.config = function()
  local vi_mode_utils = require 'feline.providers.vi_mode'

  local colors = {
    bg = '#282c34',
    fg = '#abb2bf',
    yellow = '#e0af68',
    cyan = '#56b6c2',
    darkblue = '#081633',
    green = '#98c379',
    orange = '#d19a66',
    violet = '#a9a1e1',
    magenta = '#c678dd',
    blue = '#61afef',
    red = '#e86671'
  }

  local vi_mode_colors = {
    NORMAL = colors.green,
    INSERT = colors.red,
    VISUAL = colors.magenta,
    OP = colors.green,
    BLOCK = colors.blue,
    REPLACE = colors.violet,
    ['V-REPLACE'] = colors.violet,
    ENTER = colors.cyan,
    MORE = colors.cyan,
    SELECT = colors.orange,
    COMMAND = colors.green,
    SHELL = colors.green,
    TERM = colors.green,
    NONE = colors.yellow
  }

  local default = {
    lsp = require "feline.providers.lsp",
    lsp_severity = vim.diagnostic.severity,
    config = {
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
  }

  default.icon_styles = {
    default = {
      left = "",
      right = " ",
      main_icon = "  ",
      vi_mode_icon = " ",
      position_icon = " ",
    },
    arrow = {
      left = "",
      right = "",
      main_icon = "  ",
      vi_mode_icon = " ",
      position_icon = " ",
    },

    block = {
      left = " ",
      right = " ",
      main_icon = "   ",
      vi_mode_icon = "  ",
      position_icon = "  ",
    },

    round = {
      left = "",
      right = "",
      main_icon = "  ",
      vi_mode_icon = " ",
      position_icon = " ",
    },

    slant = {
      left = " ",
      right = " ",
      main_icon = "  ",
      vi_mode_icon = " ",
      position_icon = " ",
    },
  }

  -- statusline style
  default.statusline_style = default.icon_styles[default.config.style]

  -- show short statusline on small screens
  default.shortline = default.config.shortline == false and true

  -- Initialize the components table
  default.components = {
    active = {},
    inactive = {}
  }

  default.main_icon = {
    provider = default.statusline_style.main_icon,

    right_sep = {
      str = default.statusline_style.right,
    },

    hl = {fg = colors.magenta}
  }

  default.file_name = {
    provider = function()
      local filename = vim.fn.expand "%:t"
      local extension = vim.fn.expand "%:e"
      local icon = require("nvim-web-devicons").get_icon(filename, extension)
      if icon == nil then
        icon = " "
        return icon
      end
      local bo = vim.bo
      local readonly_str = bo.readonly and '🔒' or ' '
      local modified_str = bo.modified and '●' or ' '
      return " " .. readonly_str .. " " .. icon .. " " .. filename .." " .. modified_str
    end,
    enabled = default.shortline or function(winid)
      return vim.api.nvim_win_get_width(tonumber(winid) or 0) > 70
    end,
    hl = function()
      local val = {
        name = vi_mode_utils.get_mode_highlight_name(),
        fg = vi_mode_utils.get_mode_color(),
      }
      return val
    end,
    right_sep = {
      str = default.statusline_style.right,
    },
  }

  default.inactive_file_name = {
    provider = function()
      local filename = vim.fn.expand "%:."
      local extension = vim.fn.expand "%:e"
      local icon = require("nvim-web-devicons").get_icon(filename, extension)
      if icon == nil then
        icon = " "
        return icon
      end
      local bo = vim.bo
      return " " .. icon .. " " .. filename
    end,
    enabled = default.shortline or function(winid)
      return vim.api.nvim_win_get_width(tonumber(winid) or 0) > 70
    end,
    right_sep = {
      str = default.statusline_style.right,
    },
    hl = {bg = colors.blue}
  }

  default.dir_name = {
    provider = function()
      local dir_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
      return "  " .. dir_name .. " "
    end,

    enabled = default.shortline or function(winid)
      return vim.api.nvim_win_get_width(tonumber(winid) or 0) > 80
    end,

    right_sep = {
      str = default.statusline_style.right,
    },

    hl = {fg = colors.blue}
  }

  default.diff = {
    add = {
      provider = "git_diff_added",
      icon = " ",
      hl = {fg = colors.green}
    },

    change = {
      provider = "git_diff_changed",
      icon = "  ",
      hl = {fg = colors.orange}
    },

    remove = {
      provider = "git_diff_removed",
      icon = "  ",
      hl = {fg = colors.red}
    },
  }

  default.git_branch = {
    provider = "git_branch",
    enabled = default.shortline or function(winid)
      return vim.api.nvim_win_get_width(tonumber(winid) or 0) > 70
    end,
    icon = "  ",
    hl = {
      fg = colors.violet,
      style = 'bold'
    },
  }

  default.diagnostic = {
    error = {
      provider = "diagnostic_errors",
      enabled = function()
        return default.lsp.diagnostics_exist(default.lsp_severity.ERROR)
      end,
      icon = "  ",
      hl = {fg = colors.red}
    },

    warning = {
      provider = "diagnostic_warnings",
      enabled = function()
        return default.lsp.diagnostics_exist(default.lsp_severity.WARN)
      end,
      icon = "  ",
      hl = {fg = colors.yellow}
    },

    hint = {
      provider = "diagnostic_hints",
      enabled = function()
        return default.lsp.diagnostics_exist(default.lsp_severity.HINT)
      end,
      icon = "  ",
      hl = {fg = colors.violet}
    },

    info = {
      provider = "diagnostic_info",
      enabled = function()
        return default.lsp.diagnostics_exist(default.lsp_severity.INFO)
      end,
      icon = "  ",
      hl = {fg = colors.darkblue}
    },
  }

  local navic_code_context = nil
  local ok,navic = pcall(require,'nvim-navic')
  if ok then
    navic_code_context = {
      provider = function()
        return " " .. navic.get_location()
      end,
      enabled = function()
        return navic.is_available()
      end,
      hl = {fg = colors.magenta}
    }
  end

  local illuminate_references_context = nil
  local ok,illuminate = pcall(require, 'illuminate')
  if ok then
    illuminate_references_context = {
      provider = function()
        return "   references: " .. #illuminate_references[vim.api.nvim_get_current_buf()]
      end,
      enabled = function()
        return illuminate_references ~= nil and illuminate_references[vim.api.nvim_get_current_buf()] ~= nil
      end,
      hl = {fg = colors.magenta}
    }
  end


  default.lsp_progress = {
    provider = function()
      local Lsp = vim.lsp.util.get_progress_messages()[1]

      if Lsp then
        local msg = Lsp.message or ""
        local percentage = Lsp.percentage or 0
        local title = Lsp.title or ""
        local spinners = {
          "",
          "",
          "",
        }

        local success_icon = {
          "",
          "",
          "",
        }

        local ms = vim.loop.hrtime() / 1000000
        local frame = math.floor(ms / 120) % #spinners

        if percentage >= 70 then
          return string.format(" %%<%s %s %s (%s%%%%) ", success_icon[frame + 1], title, msg, percentage)
        end

        return string.format(" %%<%s %s %s (%s%%%%) ", spinners[frame + 1], title, msg, percentage)
      end

      return ""
    end,
    enabled = default.shortline or function(winid)
      return vim.api.nvim_win_get_width(tonumber(winid) or 0) > 80
    end,
    hl = {fg = colors.magenta}
  }

  default.lsp_icon = {
    provider = function()
      if next(vim.lsp.buf_get_clients()) ~= nil then
        return " LSP"
      else
        return ""
      end
    end,
    enabled = default.shortline or function(winid)
      return vim.api.nvim_win_get_width(tonumber(winid) or 0) > 70
    end,
    hl = {
      fg = colors.blue,
      style = 'bold'
    },
  }

  default.empty_space = {
    provider = " " .. default.statusline_style.left,
  }

  -- this matches the vi mode color
  default.empty_spaceColored = {
    provider = default.statusline_style.left,
  }

  default.mode_icon = {
    provider = default.statusline_style.vi_mode_icon,
  }

  default.empty_space2 = {
    provider = function()
      return "  "
    end,
  }

  default.separator_right = {
    provider = default.statusline_style.left,
    enabled = default.shortline or function(winid)
      return vim.api.nvim_win_get_width(tonumber(winid) or 0) > 90
    end,
    hl = {fg = colors.green}
  }

  default.separator_right2 = {
    provider = default.statusline_style.left,
    enabled = default.shortline or function(winid)
      return vim.api.nvim_win_get_width(tonumber(winid) or 0) > 90
    end,
    hl = {fg = colors.green}
  }

  default.position_icon = {
    provider = default.statusline_style.position_icon,
    enabled = default.shortline or function(winid)
      return vim.api.nvim_win_get_width(tonumber(winid) or 0) > 90
    end,
  }

  default.current_line = {
    provider = function()
      local current_line = vim.fn.line "."
      local total_line = vim.fn.line "$"

      if current_line == 1 then
        return " Top "
      elseif current_line == vim.fn.line "$" then
        return " Bot "
      end
      local result, _ = math.modf((current_line / total_line) * 100)
      return " " .. result .. "%% "
    end,

    enabled = default.shortline or function(winid)
      return vim.api.nvim_win_get_width(tonumber(winid) or 0) > 90
    end,

    hl = {
      fg = colors.cyan,
      style = 'bold'
    }
  }

  local function add_table(a, b)
    table.insert(a, b)
  end

  -- components are divided in 3 sections
  default.left = {}
  default.middle = {}
  default.right = {}

  -- left
  add_table(default.left, default.main_icon)
  add_table(default.left, default.file_name)
  add_table(default.left, default.dir_name)
  add_table(default.left, default.diff.add)
  add_table(default.left, default.diff.change)
  add_table(default.left, default.diff.remove)
  add_table(default.left, default.diagnostic.error)
  add_table(default.left, default.diagnostic.warning)
  add_table(default.left, default.diagnostic.hint)
  add_table(default.left, default.diagnostic.info)
  if gps_code_context then
    add_table(default.left, gps_code_context)
  elseif navic_code_context then
    add_table(default.left, navic_code_context)
  end

  if illuminate_references_context then
    add_table(default.left, illuminate_references_context)
  end

  -- add_table(default.middle, default.lsp_progress) -- use fidget.nvim instead

  -- right
  add_table(default.right, default.lsp_icon)
  add_table(default.right, default.git_branch)
  -- add_table(default.right, default.empty_space)
  -- add_table(default.right, default.empty_spaceColored)
  -- add_table(default.right, default.mode_icon)
  add_table(default.right, default.empty_space2)
  -- add_table(default.right, default.separator_right)
  -- add_table(default.right, default.separator_right2)
  add_table(default.right, default.position_icon)
  add_table(default.right, default.current_line)

  default.components.active[1] = default.left
  default.components.active[2] = default.middle
  default.components.active[3] = default.right

  default.components.inactive[1] = {default.inactive_file_name}

  require"feline".setup {
    components = default.components,
  }
end
-->>> end

local lprint = require("core.utils").log
-- deprecated: use :Lazy profile instead
-- vim.api.nvim_create_autocmd("UIEnter", {
--   callback = function()
--     local is_mac = vim.loop.os_uname().sysname=="Darwin"
--     if is_mac then
--       print('please use startuptime to profile')
--       return
--     else
--       local pid = vim.loop.os_getpid()
--       local ctime = vim.loop.fs_stat("/proc/" .. pid).ctime
--       local start = ctime.sec + ctime.nsec / 1e9
--       local tod = { vim.loop.gettimeofday() }
--       local now = tod[1] + tod[2] / 1e6
--       local startuptime = (now - start) * 1000
--       vim.notify("startup: " .. startuptime .. "ms")
--     end
--   end,
-- })
function Buf_attach()
  -- reset keymaps
  vim.defer_fn(function ()
    local cmd_str = [[xunmap <buffer> ih]] -- NOTES: xunmap ih will not work in this case!!! buffer local keymaps should unmap using <buffer> too
    local ok_all = true
    lprint(cmd_str)
    local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok

    cmd_str = [[ounmap <buffer> ih]]
    lprint(cmd_str)
    ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok

    cmd_str = [[xunmap i%]]
    lprint(cmd_str)
    ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok

    cmd_str = [[ounmap i%]]
    lprint(cmd_str)
    ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok
  end,250) -- 250 should be enough for buffer local plugins to load
  -- require("core.utils").repeat_timer(function ()
    --   local bufnr = vim.api.nvim_get_current_buf()
    --   if vim.api.nvim_buf_is_valid(bufnr) then
    --     local ok,timer = pcall(vim.api.nvim_buf_get_var,bufnr,'timer')
    --     if not ok then
    --       timer = 0
    --     else
    --       timer = vim.api.nvim_buf_get_var(bufnr,'timer')
    --     end
    --     local ok_all = true
    --
    --     local cmd_str = [[xunmap <buffer> ih]] -- NOTES: xunmap ih will not work in this case!!! buffer local keymaps should unmap using <buffer> too
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     local cmd_str = [[ounmap <buffer> ih]]
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     local cmd_str = [[xunmap i%]]
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     local cmd_str = [[ounmap i%]]
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     -- local cmd_str = [[lua vim.api.nvim_buf_del_keymap(]] .. tostring(bufnr) .. [[ , 'x' , 'i%')]]
    --     -- lprint(cmd_str)
    --     -- local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     -- ok_all = ok_all and ok
    --
    --     if packer_plugins['vim-matchup'].loaded then
    --       vim.api.nvim_buf_set_keymap(bufnr,'x','u%','<Plug>(matchup-i%)',{silent=true, noremap=false})
    --     end
    --     if packer_plugins['gitsigns.nvim'].loaded then
    --       vim.api.nvim_buf_set_keymap(bufnr,'x','uh',':<C-U>Gitsigns select_hunk<CR>',{silent=true, noremap=false})
    --       vim.api.nvim_buf_set_keymap(bufnr,'o','uh',':<C-U>Gitsigns select_hunk<CR>',{silent=true, noremap=false})
    --     end
    --     if ok then
    --       return -1
    --     else
    --       if timer<300 then
    --         vim.api.nvim_buf_set_var(bufnr,"timer",timer+10)
    --         return 10
    --       else
    --         return -1
    --       end
    --     end
    --   end
    -- end)
  end
vim.cmd([[autocmd BufEnter * lua Buf_attach()]])
