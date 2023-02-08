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

return M
