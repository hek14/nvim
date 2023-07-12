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

local request_ts = function(locs)
  local inputs_for_treesitter = {}
  for i, loc in ipairs(locs) do
    local f = vim.uri_to_fname(loc.uri or loc.targetUri)
    local filetick = vim.loop.fs_stat(f).mtime.nsec
    local ext = vim.fn.fnamemodify(f,':e')
    local _ft = extension_to_filetype[ext]
    local range = loc.range or loc.targetRange
    table.insert(inputs_for_treesitter,{
      file = f, 
      filetick = filetick,
      filetype = _ft,
      position = {range.start.line,range.start.character},
    })
  end
  return inputs_for_treesitter
end

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
  local start = vim.loop.hrtime()
  treesitter_job:send(request_ts(locations))
  treesitter_job:with_output(function()
    print('treesitter spent: ',(vim.loop.hrtime()-start)/1e6)
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
      local ts
      pcall(function()
        ts = treesitter_job:retrieve(fname,{ range.start.line, range.start.character })
      end)
      if not ts or #ts==0 or #ts[1]==0 then
        ts = vim.fn.expand('%:t')
      else
        ts = ts[1]
      end
      table.insert(ts_infos,ts)
      start = vim.loop.hrtime()
      vim.fn.bufload(buf)
      print('load buf spent: ',(vim.loop.hrtime()-start)/1e6)
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
    -- vim.api.nvim_buf_add_highlight(pop.bufnr, ns, 'ErrorMsg', range.start.line, 0, -1)
    vim.api.nvim_buf_set_option(pig_menu.bufnr,"ft",ft)
    local ok, msg = pcall(function()
      for i = 1,#locations do
        vim.api.nvim_buf_set_extmark(pig_menu.bufnr, ns, i-1, i-1, {
          virt_lines = {
            {{ts_infos[i], "Comment"}}
          },
          virt_lines_above = true
        })
      end
    end)
    if not ok then
      print('failed: ',msg)
    end
  end)
end

