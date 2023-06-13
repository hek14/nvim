-- https://nuxsh.is-a.dev/blog/custom-nvim-statusline.html
-- https://zignar.net/2022/01/21/a-boring-statusline-for-neovim
-- https://nihilistkitten.me/nvim-lua-statusline


local fn = vim.fn
local o = vim.o
local cmd = vim.cmd

local get_column_number = function()
    return fn.col(".")
end

local filepath = function()
  local fpath = vim.fn.fnamemodify(vim.fn.expand "%", ":~:.:h")
  if fpath == "" or fpath == "." then
      return " "
  end
  return string.format(" %%<%s/", fpath)
end

local filename = function()
  local fname = vim.fn.expand "%:t"
  if fname == "" then
      return ""
  end
  return fname .. " "
end

local lsp_diagnostic = function()
  local count = {}
  local levels = {
    errors = "Error",
    warnings = "Warn",
    info = "Info",
    hints = "Hint",
  }
  for k, level in pairs(levels) do
    count[k] = vim.tbl_count(vim.diagnostic.get(0, { severity = level }))
  end
  local errors = ""
  local warnings = ""
  local hints = ""
  local info = ""
  if count["errors"] ~= 0 then
    errors = " %#LspDiagnosticsSignError# " .. count["errors"]
  end
  if count["warnings"] ~= 0 then
    warnings = " %#LspDiagnosticsSignWarning# " .. count["warnings"]
  end
  if count["hints"] ~= 0 then
    hints = " %#LspDiagnosticsSignHint# " .. count["hints"]
  end
  if count["info"] ~= 0 then
    info = " %#LspDiagnosticsSignInformation# " .. count["info"]
  end
  return errors .. warnings .. hints .. info .. "%#Normal#"
end

local lsp_client = function()
  local clients = any_client_attached()
  if #clients > 0 then
    return clients[1].name
  else
    return "NONE"
  end
end

local dap = function()
  if package.loaded['dap'] then
    return require'dap'.status()
  else
    return ""
  end
end

local vcs = function()
  local git_info = vim.b.gitsigns_status_dict
  if not git_info or git_info.head == "" then
    return ""
  end
  local added = git_info.added and ("%#GitSignsAdd#+" .. git_info.added .. " ") or ""
  local changed = git_info.changed and ("%#GitSignsChange#~" .. git_info.changed .. " ") or ""
  local removed = git_info.removed and ("%#GitSignsDelete#-" .. git_info.removed .. " ") or ""
  if git_info.added == 0 then
    added = ""
  end
  if git_info.changed == 0 then
    changed = ""
  end
  if git_info.removed == 0 then
    removed = ""
  end
  return table.concat {
     " ",
     added,
     changed,
     removed,
     " ",
     "%#GitSignsAdd# ",
     git_info.head,
     " %#Normal#",
  }
end

local filetype = function()
  return string.format(" %s ", vim.bo.filetype):upper()
end

local lineinfo = function()
  if vim.bo.filetype == "alpha" then
    return ""
  end
  return " %P %l:%c "
end

local root = function()
  local _root = vim.loop.cwd()
  local home = vim.env['HOME']
  return _root:gsub(home,'~')
end

Statusline = {}
Statusline.active = function()
  local statusline = ""
  statusline = statusline .. [[%#StatusLeft#]]
  statusline = statusline .. root() .. " | " .. vim.fn.expand('%')
  statusline = statusline .. [[ %m %r ]]
  -- statusline = statusline .. [[%=]]  -- NOTE: `%=` is separator
  -- statusline = statusline .. [[%#StatusMid#]] -- NOTE:`%#` is highlight-group
  -- statusline = statusline .. lsp_client() .. "   " .. dap()
  -- statusline = statusline .. [[%=]]
  -- statusline = statusline .. [[%#StatusRight#]]
  statusline = statusline .. [[%l,]] .. get_column_number() .. [[   ]]
  statusline = statusline .. [[%p%%]]
  statusline = statusline .. '    #'  .. vim.fn.bufnr()
  return statusline
end

function Statusline.inactive()
  return [[%F %m %r]]
end

function Statusline.short()
  return "%#StatusLineNC#   NvimTree"
end

local group = vim.api.nvim_create_augroup('kk_statusline',{clear=true})
vim.api.nvim_create_autocmd({'WinEnter','BufEnter'},{
  command = 'setlocal statusline=%!v:lua.Statusline.active()'
})
vim.api.nvim_create_autocmd({'WinLeave','BufLeave'},{
  command = 'setlocal statusline=%!v:lua.Statusline.inactive()'
})
vim.api.nvim_create_autocmd({'WinEnter','BufEnter','FileType'},{
  command = 'setlocal statusline=%!v:lua.Statusline.short()',
  pattern = 'NvimTree'
})
