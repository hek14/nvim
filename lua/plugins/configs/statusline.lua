local present, feline = pcall(require, "feline")
if not present then
   return
end

local default = {
   lsp = require "feline.providers.lsp",
   lsp_severity = vim.diagnostic.severity,
   config = require("core.utils").load_config().plugins.options.statusline,
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
}

default.diff = {
   add = {
      provider = "git_diff_added",
      icon = " ",
   },

   change = {
      provider = "git_diff_changed",
      icon = "  ",
   },

   remove = {
      provider = "git_diff_removed",
      icon = "  ",
   },
}

default.git_branch = {
   provider = "git_branch",
   enabled = default.shortline or function(winid)
      return vim.api.nvim_win_get_width(tonumber(winid) or 0) > 70
   end,
   icon = "  ",
}

default.diagnostic = {
   error = {
      provider = "diagnostic_errors",
      enabled = function()
         return default.lsp.diagnostics_exist(default.lsp_severity.ERROR)
      end,
      icon = "  ",
   },

   warning = {
      provider = "diagnostic_warnings",
      enabled = function()
         return default.lsp.diagnostics_exist(default.lsp_severity.WARN)
      end,
      icon = "  ",
   },

   hint = {
      provider = "diagnostic_hints",
      enabled = function()
         return default.lsp.diagnostics_exist(default.lsp_severity.HINT)
      end,
      icon = "  ",
   },

   info = {
      provider = "diagnostic_info",
      enabled = function()
         return default.lsp.diagnostics_exist(default.lsp_severity.INFO)
      end,
      icon = "  ",
   },
}

local ok, gps = pcall(require,"nvim-gps")
if ok then
  local gps_code_context = { -- should not use local gps_code_context: wrong namescope for later usage
    provider = function()
      local gps = require("nvim-gps")
      return string.format(" ctx: %s",gps.get_location())
    end,
    enabled = function()
      local gps = require("nvim-gps")
      return gps.is_available()
    end
  }
else
  local gps_code_context = nil
  print("gps not available")
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
}

default.lsp_icon = {
   provider = function()
      if next(vim.lsp.buf_get_clients()) ~= nil then
         return "  LSP"
      else
         return ""
      end
   end,
   enabled = default.shortline or function(winid)
      return vim.api.nvim_win_get_width(tonumber(winid) or 0) > 70
   end,
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
}

default.separator_right2 = {
   provider = default.statusline_style.left,
   enabled = default.shortline or function(winid)
      return vim.api.nvim_win_get_width(tonumber(winid) or 0) > 90
   end,
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
}

local function add_table(a, b)
   table.insert(a, b)
end

local M = {}
M.setup = function(override_flag)
   if override_flag then
      default = require("core.utils").tbl_override_req("feline", default)
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
   end

   add_table(default.middle, default.lsp_progress)

   -- right
   add_table(default.right, default.lsp_icon)
   add_table(default.right, default.git_branch)
   add_table(default.right, default.empty_space)
   add_table(default.right, default.empty_spaceColored)
   add_table(default.right, default.mode_icon)
   add_table(default.right, default.empty_space2)
   add_table(default.right, default.separator_right)
   add_table(default.right, default.separator_right2)
   add_table(default.right, default.position_icon)
   add_table(default.right, default.current_line)

   default.components.active[1] = default.left
   default.components.active[2] = default.middle
   default.components.active[3] = default.right

   default.components.inactive[1] = {default.inactive_file_name}

   feline.setup {
      components = default.components,
   }
end

return M
