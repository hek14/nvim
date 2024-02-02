local conditions = require("plugins.lualine.conditions")

local function color(highlight_group, content)
  return "%#" .. highlight_group .. "#" .. content .. "%*"
end

local diff_source = function ()
  local gitsigns = vim.b.gitsigns_status_dict
  if gitsigns then
    return {
      added = gitsigns.added,
      modified = gitsigns.changed,
      removed = gitsigns.removed,
    }
  end
end

local winbar = function ()
  local navic = require('nvim-navic') 
  local filename = vim.fn.expand('%:t')
  if navic.is_available() then
    local loc = navic.get_location()
    if loc=="" then
      return filename
    else
      return filename .. ' > ' .. loc
    end
  else
    return filename
  end
end

local inactive_winbar = function ()
  local filename = vim.fn.expand('%:p')
  local home = vim.fn.expand("$HOME") .. '/'
  filename = string.gsub(filename, home, '')
  return filename
end

local total_ref 
local current_loc
local current_tick

local reference_hint = function ()
  local buf = vim.api.nvim_get_current_buf()
  if not package.loaded['illuminate'] then
    return ""
  else
    local refs = _G.illuminate_references[buf]
    if current_tick~=_G.illuminate_update_tick[buf] then
      total_ref = #refs
      current_tick = _G.illuminate_update_tick[buf]
      local current_line = vim.api.nvim_win_get_cursor(0)[1]
      local current_col = vim.api.nvim_win_get_cursor(0)[2]
      for i,ref in ipairs(refs) do
        local _start = ref.range.start
        local _end = ref.range['end']
        local condition = _start.line+1 == current_line and
        _start.character <= current_col and
        _end.line+1 >= current_line and
        _end.character >= current_col
        if condition then
          current_loc = i
          break
        end
      end
      if current_loc == nil then
        current_loc = 'ERR'
      end
    end
    return string.format("%d|%d",current_loc,total_ref)
  end
end

local lsp_name = function ()
  local clients = any_client_attached() 
  local names = ""
  for _,client in ipairs(clients) do
    names = names .. client.name .. "|"
  end
  names = string.sub(names,1,#names-1)
  return names
end

local function pwd()
  local win = vim.api.nvim_get_current_win()
  local path = vim.fn.getcwd(win)
  path =  string.gsub(path,vim.env['HOME'],'~')
  if path=='~' then
    return "HOME"
  else
    return path
  end
end



return {
  mode = {
    function()
      return " "
    end,
    padding = { left = 0, right = 0 },
    color = {},
    cond = nil,
  },
  branch = {
    "b:gitsigns_head",
    icon = "",
    cond = conditions.hide_in_width,
  },
  diff = {
    "diff",
    source = diff_source,
    symbols = { added = "+", modified = "~", removed = "-" },
    colored = false,
    cond = nil,
  },
  diagnostics = {
    "diagnostics",
    sources = { "nvim_diagnostic" },
    symbols = { error = " ", warn = " ", info = " ", hint = "󰌶 " },
    cond = nil,
  },
  treesitter = {
    function()
      local b = vim.api.nvim_get_current_buf()
      if next(vim.treesitter.highlighter.active[b]) then
        return "  "
      end
      return ""
    end,
    cond = conditions.hide_in_width,
  },
  lsp = {
    function(msg)
      msg = msg or "LS Inactive"
      local bufnr = vim.api.nvim_get_current_buf()
      local buf_clients = vim.lsp.get_active_clients({ bufnr = bufnr })
      if next(buf_clients) == nil then
        if type(msg) == "boolean" or #msg == 0 then
          return "LS Inactive"
        end
        return msg
      end
      local buf_client_names = {}

      -- add client
      for _, client in pairs(buf_clients) do
        if client.name == "copilot" then
          table.insert(buf_client_names, "")
        elseif client.name == "typescript-tools" then
          table.insert(buf_client_names, "󰛦 Typescript")
        elseif client.name ~= "null-ls" then
          table.insert(buf_client_names, client.name)
        end
      end

      -- -- add formatter
      -- local formatters = require("dlvhdr.plugins.formatting.formatters")
      -- local supported_formatters = formatters.list_registered(bufnr)
      -- vim.list_extend(buf_client_names, supported_formatters)
      --
      -- -- add linter
      -- local linters = require("dlvhdr.plugins.lsp.servers.none-ls.linters")
      -- local supported_linters = linters.list_registered(buf_ft)
      -- vim.list_extend(buf_client_names, supported_linters)

      local unique_client_names = vim.fn.sort(buf_client_names)
      unique_client_names = vim.fn.uniq(unique_client_names)
      return table.concat(unique_client_names, "  ")
    end,
  },
  location = {
    "location",
    cond = conditions.hide_in_width,
  },
  progress = {
    "progress",
    cond = conditions.hide_in_width,
  },
  spaces = {
    function()
      local label = "Spaces: "
      if not vim.api.nvim_buf_get_option(0, "expandtab") then
        label = "Tab size: "
      end
      return label .. vim.api.nvim_buf_get_option(0, "shiftwidth") .. " "
    end,
    cond = conditions.hide_in_width,
  },
  encoding = {
    "o:encoding",
    fmt = string.upper,
    cond = conditions.hide_in_width,
  },
  filetype = {
    "filetype",
    cond = conditions.hide_in_width,
  },
  filename = {
    function()
      local bufnum = vim.fn.winbufnr()

      local segments = {}

      -- File name
      local file_name = vim.fn.fnamemodify(vim.fn.bufname(bufnum), ":t")
      local extension = vim.fn.expand("#" .. bufnum .. ":e")
      local icon, devicon_color = require("nvim-web-devicons").get_icon_color(file_name, extension)

      if not icon and #file_name == 0 then
        -- Is in a folder
        icon = ""
      end

      -- File modified
      local bufname = vim.fn.bufname(bufnum)
      if bufname ~= "" and vim.fn.getbufvar(bufnum, "&modified") == 1 then
        table.insert(segments, color("DiagnosticWarn", ""))
      end

      -- Read only
      if vim.fn.getbufvar(bufnum, "&readonly") == 1 then
        table.insert(segments, color("StatuslineBoolean", ""))
      end

      -- Icon

      local icon_statusline = color("LuaLineFileIcon", icon or "")
      table.insert(segments, icon_statusline)

      -- File path
      local file_path = '%{expand("%:t")}'
      table.insert(segments, file_path)

      return table.concat(segments, " ")
    end,
  },
  scrollbar = {
    function()
      local current_line = vim.fn.line(".")
      local total_lines = vim.fn.line("$")
      local chars = { "_", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
      local line_ratio = current_line / total_lines
      local index = math.ceil(line_ratio * #chars)
      return chars[index]
    end,
    padding = { left = 0, right = 0 },
    cond = nil,
  },
}
