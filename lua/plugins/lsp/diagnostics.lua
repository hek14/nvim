local M = {}
local log = require('core.utils').log

local function lspSymbol(name, icon)
  local hl = "DiagnosticSign" .. name
  vim.fn.sign_define(hl, {text = icon, numhl = hl, texthl = hl})
end

-- NOTE: refer to: https://github.com/neovim/nvim-lspconfig/issues/726#issuecomment-1075539112
local function filter(arr, func)
  -- Filter in place
  -- https://stackoverflow.com/questions/49709998/how-to-filter-a-lua-array-inplace
  local new_index = 1
  local size_orig = #arr
  for old_index, v in ipairs(arr) do
    if func(v, old_index) then
      arr[new_index] = v
      new_index = new_index + 1
    end
  end
  for i = new_index, size_orig do arr[i] = nil end
end


local current_symbols = nil
local current_diagnostics = nil
local current_arg_1 = nil
local current_arg_2 = nil
local current_arg_3 = nil
local current_arg_4 = nil
local current_arg_5 = nil
local timer = nil


local function filter_diagnostics(diagnostic)
  -- Only filter out Pyright stuff for now
  -- To get line diagnostics :lua =vim.lsp.diagnostic.get_line_diagnostics()
  if diagnostic.source == "Lua Diagnostics." then
    if string.match(diagnostic.message, 'Undefined global.*vim') then
      return false
    end
    if string.match(diagnostic.message, 'Deprecated.*current is Lua') then
      return false
    end
    if string.match(diagnostic.message, 'Line with postspace') then
      return false
    end
    return true
  end

  if diagnostic.source == "Pyright" then
    if string.match(diagnostic.message,'.*is not accessed') then
      local found = nil
      for i,symbol in ipairs(current_symbols) do
        if vim.deep_equal(diagnostic.range,symbol.range) then 
          found = symbol
        end
      end
      if found == nil then
        return false  -- not found: it's not documentSymbol, maybe function/module/package, just filter it
      else
        if lsp_num_to_str[found.kind] == 'Variable' then
          print('found Variable unused')
          return true
        else
          print('found ' .. found.kind  ' unused, it is fine!')
          return false
        end
      end
    else
      return true
    end
  end
end

local resolve_document_symbols = function()
  local start = vim.loop.hrtime()
  local bufnr = vim.fn.bufnr()
  local client = any_client_attached() or {}
  if #client ==0 then
    print('no client')
    current_symbols = nil
    return
  end
  local symbols = vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol",{ textDocument = vim.lsp.util.make_text_document_params(bufnr) })
  if symbols == nil then 
    print('no symbols')
    current_symbols = nil
    return
  end
  local items = symbols[client[1].id].result
  if #items==0 then
    print('no symbols')
    current_symbols = nil
    return
  end

  -- flatten them
  local results = {}
  local stack = {}
  for i,item in ipairs(items) do
    if item.children==nil or #item.children==0 then
      item.children = nil
      results[#results+1] = item
    else
      stack[#stack+1] = item
    end
  end

  while #stack > 0 do
    local curr = stack[#stack]
    stack[#stack] = nil
    if curr.children~=nil and #curr.children > 0 then
      for i,child in ipairs(curr.children) do
        stack[#stack+1] = child
      end
    end
    curr.children = nil
    results[#results+1] = curr
  end

  current_symbols = results
  _G.current_document_symbols = current_symbols
  filter(current_diagnostics, filter_diagnostics)
  vim.lsp.diagnostic.on_publish_diagnostics(current_arg_1,current_arg_2,current_arg_3,current_arg_4,current_arg_5)
  print('resolve: ' .. #current_symbols .. ' symbols spent: ' .. ((vim.loop.hrtime() - start) / 1000000) .. "ms")
  timer:close()
  timer = nil
end
_G.F = resolve_document_symbols



local function custom_on_publish_diagnostics(a, params, client_id, c, config)
  print("custom_on_publish_diagnostics called")
  current_diagnostics = params.diagnostics
  current_arg_1 = a
  current_arg_2 = params
  current_arg_3 = client_id
  current_arg_4 = c
  current_arg_5 = config
  if timer==nil then
    timer = vim.loop.new_timer()
    timer:start(0,0, function()
      vim.schedule(resolve_document_symbols)
    end)
  end
end


function M.setup()
  lspSymbol("Error", "")
  lspSymbol("Info", "")
  lspSymbol("Hint", "")
  lspSymbol("Warn", "")

  -- Automatically update diagnostics
  vim.diagnostic.config({
    underline = false,
    update_in_insert = false,
    virtual_text = {spacing = 4, prefix = "●"},
    severity_sort = true
  })
  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(custom_on_publish_diagnostics,{})
end

return M
