local M = {}
local channel = require("plenary.async.control").channel
local sorters = require "telescope.sorters"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local pickers = require "telescope.pickers"
local utils = require "telescope.utils"
local entry_display = require "telescope.pickers.entry_display"
local action_set = require 'telescope.actions.set'
local action_state = require 'telescope.actions.state'
local actions = require 'telescope.actions'
local scan = require 'plenary.scandir'
local log = require('core.utils').log
local fmt = string.format
local treesitter_job = require('scratch.bridge_ts_parse')

local function inject_ts_to_lsp_symbols(locations,f,start)
  local cancel = function() end
  local ratio = 0.2
  for i, loc in ipairs(locations) do
    loc.ts_info = ""
  end
  return function(prompt)
    local tx, rx = channel.oneshot()
    cancel()
    cancel = treesitter_job:with_output(tx,ratio)
    ratio = ratio + 0.1 <= 1.0 and ratio + 0.1 or 1.0
    local res = rx()
    if res then
      for i, loc in ipairs(locations) do
        loc.ts_info = treesitter_job:retrieve(f or loc.filename, {loc.lnum-1,loc.col-1})
      end
      local done,done_ratio = treesitter_job:done()
      log(fmt("my telescope LSP-TS %s done after: %dms",done_ratio,(vim.loop.hrtime()-start)/1e6))
    end
    return locations
  end
end

local function gen_lsp_and_ts_symbols(opts)
  opts = opts or {}
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  -- Default we have two columns, symbol and type(unbound)
  -- If path is not hidden then its, filepath, symbol and type(still unbound)
  -- If show_line is also set, type is bound to len 8
  local display_items = {
    { width = opts.symbol_width or 25 },
    { remaining = true },
  }

  local hidden = utils.is_path_hidden(opts)
  if not hidden then
    table.insert(display_items, 1, { width = vim.F.if_nil(opts.fname_width, 30) })
  end

  if opts.show_line then
    -- bound type to len 8 or custom
    table.insert(display_items, #display_items, { width = opts.symbol_type_width or 8 })
  end

  local displayer = entry_display.create {
    separator = " ",
    hl_chars = { ["["] = "TelescopeBorder", ["]"] = "TelescopeBorder" },
    items = display_items,
  }
  local type_highlight = {
    ["Class"] = "TelescopeResultsClass",
    ["Constant"] = "TelescopeResultsConstant",
    ["Field"] = "TelescopeResultsField",
    ["Function"] = "TelescopeResultsFunction",
    ["Method"] = "TelescopeResultsMethod",
    ["Property"] = "TelescopeResultsOperator",
    ["Struct"] = "TelescopeResultsStruct",
    ["Variable"] = "TelescopeResultsVariable",
  }

  local make_display = function(entry)
    local msg
    if opts.show_line then
      msg = vim.trim(vim.F.if_nil(vim.api.nvim_buf_get_lines(bufnr, entry.lnum - 1, entry.lnum, false)[1], ""))
    end
    return displayer {
      entry.symbol_name,
      entry.ts_info,
      -- { entry.symbol_type:lower(), type_highlight[entry.symbol_type] },
      msg,
    }
  end

  return function(entry)
    local filename = entry.filename
    local symbol_msg = entry.text
    local symbol_type, symbol_name = symbol_msg:match "%[(.+)%]%s+(.*)"
    local ordinal = ""
    if not hidden and filename then
      ordinal = filename .. " "
    end
    ordinal = ordinal .. symbol_name .. entry.ts_info
    -- ordinal = ordinal .. symbol_name
    return make_entry.set_default_entry_mt({
      value = entry,
      ordinal = ordinal,
      display = make_display,
      ts_info = entry.ts_info,

      filename = filename,
      lnum = entry.lnum,
      col = entry.col,
      symbol_name = symbol_name,
      symbol_type = symbol_type,
      start = entry.start,
      finish = entry.finish,
    }, opts)
  end
end


M.lsp_symbols = function(opts)
  local start = vim.loop.hrtime()
  opts = opts or {}
  local params = vim.lsp.util.make_position_params(opts.winnr)
  vim.lsp.buf_request(opts.bufnr, "textDocument/documentSymbol", params, function(err, result, _, _)
    if err then
      vim.api.nvim_err_writeln("Error when finding document symbols: " .. err.message)
      return
    end

    if not result or vim.tbl_isempty(result) then
      return
    end

    local locations = vim.lsp.util.symbols_to_items(result or {}, opts.bufnr) or {}
    locations = utils.filter_symbols(locations, opts)
    if locations == nil then
      return
    end

    if vim.tbl_isempty(locations) then
      utils.notify("builtin.lsp_document_symbols", {
        msg = "No document_symbol locations found",
        level = "INFO",
      })
      return
    end

    local inputs_for_treesitter = {}
    local f = vim.api.nvim_buf_get_name(0)
    local ft = vim.api.nvim_buf_get_option(0,'filetype')
    local filetick = vim.loop.fs_stat(f).mtime.nsec
    for i,item in ipairs(locations) do
      table.insert(inputs_for_treesitter,{
        file = f, 
        filetick = filetick,
        filetype = ft,
        position = {item.lnum-1,item.col-1},
      })
    end

    treesitter_job:send(inputs_for_treesitter)
    treesitter_job:with_output(function ()
      opts.path_display = { "hidden" }
      for i, loc in ipairs(locations) do
        loc.ts_info = treesitter_job:retrieve(f or loc.filename, {loc.lnum-1,loc.col-1})
      end
      pickers
      .new(opts, {
        prompt_title = "LSP Document Symbols",
        finder = finders.new_table {
          results = locations,
          entry_maker = gen_lsp_and_ts_symbols(opts)
        },
        -- finder = finders.new_dynamic {
          --   entry_maker = gen_lsp_and_ts_symbols(opts),
          --   fn = inject_ts_to_lsp_symbols(locations,f,start),
          -- },
          previewer = conf.qflist_previewer(opts),
          sorter = conf.prefilter_sorter {
            tag = "symbol_type",
            sorter = conf.generic_sorter(opts),
          },
          push_cursor_on_edit = true,
          push_tagstack_on_edit = true,
        }):find()
    end)
  end)
end


local function gen_lsp_and_ts_references(opts)
  opts = opts or {}
  local items = {
    { width = 30 },
    { remaining = true },
  }
  local displayer = entry_display.create { separator = " ▏", items = items }

  local make_display = function(entry)
    local input = {}
    table.insert(input, string.format("%s:%d:%d", utils.transform_path(opts, entry.filename), entry.lnum, entry.col))
    table.insert(input,entry.ts_info)
    local text = entry.text
    if opts.trim_text then
      text = text:gsub("^%s*(.-)%s*$", "%1")
    end
    text = text:gsub(".* | ", "")
    table.insert(input, text)
    return displayer(input)
  end

  return function(entry)
    local filename = entry.filename
    return make_entry.set_default_entry_mt({
      value = entry,
      ordinal = filename .. " " .. entry.text .. entry.ts_info,
      -- ordinal = filename .. " " .. entry.text,
      display = make_display,
      ts_info = entry.ts_info,

      bufnr = entry.bufnr,
      filename = filename,
      lnum = entry.lnum,
      col = entry.col,
      text = entry.text,
      start = entry.start,
      finish = entry.finish,
    }, opts)
  end
end


local refresh
refresh = function(locations,prompt_bufnr,opts)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local current_input = action_state.get_current_line()
  actions._close(prompt_bufnr, current_picker.initial_mode == 'insert')

  local fucked_up = 0
  for i, loc in ipairs(locations) do
    loc.ts_info = treesitter_job:retrieve(loc.filename, {loc.lnum-1,loc.col-1})
    if loc.ts_info == 'processing' then
      fucked_up = fucked_up + 1
    end
  end
  print(string.format('total: %d, fucked remaining: %d',#locations,fucked_up))
  pickers
  .new(opts, {
    prompt_title = "LSP References",
    finder = finders.new_table {
      results = locations,
      entry_maker = gen_lsp_and_ts_references(opts)
    },
    -- attach_mappings = function(_, map)
    --   map("i", "<C-r>", function(_prompt_bufnr)
    --     refresh(locations, _prompt_bufnr, opts)
    --   end)
    --   return true
    -- end,
    attach_mappings = function(_, map)
      -- NOTE: why use this? because the dynamic finder will resolve the results once the prompt_buffer is changed, so we can simulate the user input to force the dynamic update
      map("i", "<C-r>", function(_prompt_bufnr)
        print("<C-r>called!!")
        local dumb = 'nothing'
        vim.api.nvim_feedkeys(dumb,'n',false)
        local del_key = string.rep('<BS>',#dumb)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(del_key,true,false,true),'n',false)
      end)
      return true
    end,
    default_text = current_input,
    previewer = conf.qflist_previewer(opts),
    sorter = conf.generic_sorter(opts),
    push_cursor_on_edit = true,
    push_tagstack_on_edit = true,
  })
  :find()
end

M.references = function(opts)
  local start = vim.loop.hrtime()
  opts = opts or {bufnr = vim.api.nvim_get_current_buf(), winnr = vim.api.nvim_get_current_win()}
  local filepath = vim.api.nvim_buf_get_name(opts.bufnr)
  local lnum = vim.api.nvim_win_get_cursor(opts.winnr)[1]
  local params = vim.lsp.util.make_position_params()
  params.context = {
    includeDeclaration = true,
  }

  vim.lsp.buf_request(opts.bufnr, "textDocument/references", params, function(err, result, ctx, _)
    if err then
      vim.api.nvim_err_writeln("Error when finding references: " .. err.message)
      return
    end

    local locations = vim.lsp.util.locations_to_items(result, vim.lsp.get_client_by_id(ctx.client_id).offset_encoding)
    if not locations or #locations== 0 then
      vim.notify('No references found')
      log('no references')
      return
    end
    local start = vim.loop.hrtime()
    local inputs_for_treesitter = {}
    local ft = vim.api.nvim_buf_get_option(opts.bufnr,'filetype')
    for i,item in ipairs(locations) do
      table.insert(inputs_for_treesitter,{
        file = item.filename,
        filetick = vim.loop.fs_stat(item.filename).mtime.nsec,
        filetype = ft,
        position = {item.lnum-1,item.col-1},
      })
    end

    local start = vim.loop.hrtime()
    treesitter_job:send(inputs_for_treesitter)

    -- pickers
    -- .new(opts, {
    --   prompt_title = "LSP References with treesitter_job",
    --   finder = finders.new_dynamic {
    --     entry_maker = gen_lsp_and_ts_references(opts),
    --     fn = inject_ts_to_lsp_symbols(locations,nil,start),
    --   },
    --   attach_mappings = function(_, map)
    --     -- NOTE: why use this? because the dynamic finder will resolve the results once the prompt_buffer is changed, so we can simulate the user input to force the dynamic update
    --     map("i", "<C-r>", function(_prompt_bufnr)
    --       print("<C-r>called!!")
    --       local dumb = 'nothing'
    --       vim.api.nvim_feedkeys(dumb,'n',false)
    --       local del_key = string.rep('<BS>',#dumb)
    --       vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(del_key,true,false,true),'n',false)
    --     end)
    --     return true
    --   end,
    --   previewer = conf.qflist_previewer(opts),
    --   sorter = conf.generic_sorter(opts),
    --   push_cursor_on_edit = true,
    --   push_tagstack_on_edit = true,
    -- }):find()

    local ratio
    treesitter_job:with_output(function()
      print(string.format('treesitter_job reference %d symbols spent time: %s ms',#locations,(vim.loop.hrtime()-start)/1000000))
      for i, loc in ipairs(locations) do
        loc.ts_info = treesitter_job:retrieve(loc.filename, {loc.lnum-1,loc.col-1})
      end
      pickers
      .new(opts, {
        prompt_title = "LSP References",
        finder = finders.new_table {
          results = locations,
          entry_maker = gen_lsp_and_ts_references(opts)
        },
        attach_mappings = function(_, map)
          map("i", "<C-r>", function(_prompt_bufnr)
            refresh(locations, _prompt_bufnr, opts)
          end)
          return true
        end,
        previewer = conf.qflist_previewer(opts),
        sorter = conf.generic_sorter(opts),
        push_cursor_on_edit = true,
        push_tagstack_on_edit = true,
      })
      :find()
    end, ratio)
  end)
end


return M
