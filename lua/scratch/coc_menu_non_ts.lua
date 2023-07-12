local Menu = require("nui.menu")
local Layout = require("nui.layout")
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event

local extension_to_filetype = {
  ['lua'] = 'lua',
  ['py'] = 'python',
  ['cpp'] = 'cpp',
  ['c'] = 'c',
}


local menu_opts = {
  position = "50%",
  -- position = {
  --   row = 0,
  --   col = 0,
  -- },
  size = {
    width = 60,
    height = math.floor(vim.fn.winheight(0)*0.4),
  },
  -- relative = "cursor",
  border = {
    style = "single",
    text = {
      top = "COC Menu:🐷",
      top_align = "center",
    },
  },
  -- win_options = {
  --   winhighlight = "Normal:Normal,FloatBorder:Normal",
  -- }
}

local layout_opts = {
  position = "50%",
  size = {
    width = 140,
    height = math.floor(vim.fn.winheight(0)*0.4),
  }
}

local ns = vim.api.nvim_create_namespace('kkcoc')
function create_menu()
  local locations = vim.fn.CocAction('references')
  local ft = vim.api.nvim_buf_get_option(0,'ft')
  local ts_infos = {}
  local pop = Popup( { border = "single",
  size = {
    width = 120,
    height = 40,
  },
  buf_options = {
    modifiable = false,
    readonly = true,
    ft = ft
  },
  focusable = true,
  })
  local ref_lines = { Menu.separator("References") }
  for i, loc in ipairs(locations) do
    local uri = loc.uri or loc.targetUri
    local buf = vim.uri_to_bufnr(uri)
    local fname = vim.api.nvim_buf_get_name(buf)
    local range = loc.range or loc.targetRange
    vim.fn.bufload(buf)
    local text = vim.api.nvim_buf_get_lines(buf, range.start.line, range.start.line+1, false)[1]
    table.insert(ref_lines,Menu.item(text or 'nothing', {loc=loc, buf=buf}))
  end
  local pig_menu = Menu(menu_opts,{
    lines = ref_lines,
    min_width = math.floor(vim.fn.winwidth(0)*0.4),
    -- max_width = math.floor(vim.fn.winwidth(0)*0.8),
    keymap = {
      focus_next = { "n", "<Down>", "<Tab>" },
      focus_prev = { "e", "<Up>", "<S-Tab>" },
      close =  { "<Esc>", "<C-c>" },
      submit = { "<CR>", "<Space>" },
    },
    should_skip_item = function(node)
      return node._type == "separator" or node.skip
    end,
    on_close = function()
      vim.api.nvim_buf_clear_namespace(0,ns,0,-1)
    end,
    on_submit = function(item)
      vim.lsp.util.jump_to_location(item.loc,"utf-16")
    end,
    on_change = function(node,menu)
      if pop.winid then
        local range = node.loc.range or node.loc.targetRange
        vim.api.nvim_win_set_buf(pop.winid, node.buf)
        vim.api.nvim_win_set_cursor(pop.winid, {range.start.line, range.start.character})
        -- vim.api.nvim_buf_add_highlight(pop.bufnr, ns, 'ErrorMsg', range.start.line, 0, -1)
      end
    end,
  })
  local layout = Layout(layout_opts,
  Layout.Box({
    Layout.Box(pig_menu, { size = "50%" }),
    Layout.Box(pop, { size = "50%" }),
  }, { dir = "row" })
  )
  layout:mount()
  local tree = pig_menu._tree
  local nodes = tree:get_nodes()
  local range = nodes[2].loc.range or nodes[2].loc.targetRange
  vim.api.nvim_win_set_buf(pop.winid, nodes[2].buf)
  vim.api.nvim_win_set_cursor(pop.winid, {range.start.line, range.start.character})
  vim.api.nvim_buf_set_option(pig_menu.bufnr,"ft",ft)
end
