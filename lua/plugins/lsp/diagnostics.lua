-- NOTE: refer to https://github.com/rmagatti/goto-preview
local M = {}
local timer = {}
local log = require('core.utils').log
local uv = vim.loop
local function safe_close(handle)
  if not uv.is_closing(handle) then
    uv.close(handle)
  end
end
local function lspSymbol(name, icon)
  local hl = "DiagnosticSign" .. name
  vim.fn.sign_define(hl, {text = icon, numhl = hl, texthl = hl})
end

-- NOTE: refer to: https://github.com/neovim/nvim-lspconfig/issues/726#issuecomment-1075539112
local function filter(arr, func, args)
  -- Filter in place
  -- https://stackoverflow.com/questions/49709998/how-to-filter-a-lua-array-inplace
  local new_index = 1
  local size_orig = #arr
  for old_index, v in ipairs(arr) do
    if func(v, old_index, args) then
      arr[new_index] = v
      new_index = new_index + 1
    end
  end
  for i = new_index, size_orig do arr[i] = nil end
end


local filter_rule_fn_lua = function (diagnostic,old_index,symbols)
  if string.match(diagnostic.message, 'Unused local.*') then
    return false
  end
  if string.match(diagnostic.message, 'Unused function.*') then
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

local handle_import = function(diagnostic)
  local buf = vim.api.nvim_get_current_buf()
  local line = diagnostic.range.start.line
  local text = vim.api.nvim_buf_get_lines(buf,line,line+1,false)[1]
  local module_name = string.sub(text,diagnostic.range.start.character,diagnostic.range['end'].character)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local handle,pid_or_err
  local no_module_found = false
  local other_err = false
  local opts = {
    args = {"-c",text},
    stdio = { nil, stdout, stderr }
  }
  handle, pid_or_err = uv.spawn("python", opts, function(code)
    uv.read_stop(stdout)
    uv.read_stop(stderr)
    safe_close(handle)
    safe_close(stdout)
    safe_close(stderr)
    if no_module_found then
      print(string.format("module %s is actually not there",module_name))
    else
      if other_err then
        print(string.format("err: %s",other_err))
      else
        vim.notify("no err:!!! ",no_module_found,other_err)
        print("no err:!!! ",no_module_found,other_err)
        local clients = vim.lsp.buf_get_clients(buf)
        for id,client in pairs(clients) do
          if client.name=='pylance' then
            print('try to fix!!! pylance')
            client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
          end
        end
      end
    end
  end)
  uv.read_start(stderr, function(err, data)
    if data and string.match(data,'ModuleNotFoundError') then
      no_module_found = true
    else
      other_err = data
    end
  end)
end

local filter_rule_fn_python = function(diagnostic,old_index,symbols)
  if (diagnostic.code and string.match(diagnostic.code,'reportMissingImports')) or
    (diagnostic.message and string.match(diagnostic.message, 'Import.*could not be resolved'))
    then
      handle_import(diagnostic)
    end
  if (diagnostic.message and string.match(diagnostic.message,'not accessed')) then
    return false
  end
  return true
end

local function filter_rule_fn(diagnostic,old_index,symbols)
  -- Only filter out Pyright stuff for now
  -- To get line diagnostics :lua =vim.lsp.diagnostic.get_line_diagnostics()
  if diagnostic.source == "Lua Diagnostics." then
    return filter_rule_fn_lua(diagnostic,old_index,symbols)
  end
  if diagnostic.source == "Pyright"  or diagnostic.source == 'Pylance' then
    return filter_rule_fn_python(diagnostic,old_index,symbols)
  end
  return true
end


local resolve_document_symbols = function(bufnr,client_id)
  local start = vim.loop.hrtime()
  local symbols = vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol",{ textDocument = vim.lsp.util.make_text_document_params(bufnr) })
  if symbols == nil then 
    return nil
  end
  local items = symbols[client_id].result
  if #items==0 then
    return nil
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

  _G.current_document_symbols = results
  return results
end

local handle_diagnostics = function(a,params,client_id,c,config,bufnr)
  local results = nil
  -- results = resolve_document_symbols(bufnr,client_id.client_id) -- NOTE: currently too slow using lsp
  filter(params.diagnostics, filter_rule_fn, results)
  vim.lsp.diagnostic.on_publish_diagnostics(a, params, client_id, c, config)
end


local function custom_on_publish_diagnostics(a, params, client_id, c, config)
  local bufnr = vim.fn.bufnr()
  if timer[bufnr]~=nil then
    timer[bufnr]:stop() -- NOTE: timer:stop will need some time, so there maybe two timer call at the same time
  else
    timer[bufnr] = vim.loop.new_timer()
  end
  timer[bufnr]:start(100,0, vim.schedule_wrap(function ()
    handle_diagnostics(a,params,client_id,c,config,bufnr)
  end))
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
