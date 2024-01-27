local M = {}
-- TODO: why we need to manually add runtimepath in 'headless' mode
vim.opt.runtimepath:append(',~/.local/share/nvim/lazy/nvim-treesitter')
local ts_parsers = require("nvim-treesitter.parsers")
local uv = vim.loop

local log = require'core.utils'.log
local sel = require('scratch.serialize')
local fmt = string.format
local coding_util = require('scratch.stream_coding')
local get_scope = require('scratch.ts_util').get_scope
local get_type = require('scratch.ts_util').get_type
local watch_util = require('scratch.file_watcher')

local profiler = function (what)
  local start = vim.loop.hrtime()
  return { 
    finish = function ()
      -- log(string.format('%s spent time: %s ms',what or "",(vim.loop.hrtime()-start)/1000000)) 
    end}
end

-- states
local parse_results = {}


local reset_file_data = function(file,new_filetick,new_bufnr,new_filetype)
  -- reset everything, leave away all of the cached parsing results
  parse_results[file] = {}
  parse_results[file].filetick = new_filetick
  parse_results[file].bufnr = new_bufnr
  parse_results[file].filetype = new_filetype 
end


local reload_and_reparse_file = function(item)
  assert(vim.loop.fs_stat(item.file),"file not exists")
  vim.api.nvim_command(fmt('noautocmd edit %s',item.file)) -- the edit command will re-use buffer if the file is already opened
  local bufnr = vim.fn.bufnr(item.file) -- will return the existed bufnr if opened before

  -- NOTE: should set the filetype manually for treesitter parse, because we use noautocmd
  local ok, _ = pcall(vim.api.nvim_buf_set_option,bufnr,'filetype',item.filetype)
  if not ok then
    -- log("cannot set filetyte")
  end
  local filelang = ts_parsers.ft_to_lang(item.filetype)
  local parser = ts_parsers.get_parser(bufnr, filelang)
  local tree = parser:parse() -- NOTE: very important to attach a parser to this bufnr
  -- log('file reloaded! ',item.file)
  reset_file_data(item.file,item.filetick,bufnr,item.filetype)
end


local on_file_modified = function(path,filetick_now)
  -- log('update path and parse the buffer: ',path, filetick_now)
  if parse_results[path].filetick ~= filetick_now then -- maybe the send function already update it
    local item = {file = path, filetick = filetick_now, filetype = parse_results[path].filetype}
    local ok, err = pcall(reload_and_reparse_file,item)
    if not ok then 
      -- log(fmt('cannot automatically reload_and_reparse_file for ',path),err)
    end
    -- log(fmt('watcher update: [%s]: ',path))
  else
    -- log(fmt("the handle function already update file: %s",path))
  end
end

local make_file_pos_key = function(file,position)
  return fmt('file:%s,row:%s,scol:%s',file,position[1],position[2])
end

local make_pos_key = function(position)
  return fmt('row:%s,col:%s',position[1],position[2])
end

local set_file_pos_result = function(file,pos,str)
  local pos_key = make_pos_key(pos)
  parse_results[file][pos_key] = str  
end

local get_file_pos_result = function (file,pos)
  local pos_key = make_pos_key(pos)
  return parse_results[file][pos_key]
end

local update_parse_results = function(item)
  local existed_result = get_file_pos_result(item.file,item.position)
  if existed_result then 
    -- log('just using the cached value')
    return existed_result 
  end

  local new_res = get_scope(parse_results[item.file].bufnr,item.position)
  local is_definition = get_type(parse_results[item.file].bufnr,item.position)
  if not new_res then
    return {'error',is_definition}
  elseif new_res == "" then
    return {'root',is_definition}
  else
    return {new_res,is_definition}
  end
end


local watch_input = function (input)
  local added = {}
  for _,item in ipairs(input) do 
    if vim.loop.fs_stat(item.file) then
      if not vim.tbl_contains(added,item.file) then
        watch_util.add_watcher(item.file,on_file_modified)
        table.insert(added, item.file)
      end
    end
  end
end

local langtree_input = function(input)
  local added = {} 
  local cannot_parse = {}
  for _,item in ipairs(input) do 
    if parse_results[item.file] and parse_results[item.file].filetick==item.filetick then
      -- log(fmt('parse existed file: %s',item.file))
      goto continue
    end

    if vim.loop.fs_stat(item.file) then
      if not vim.tbl_contains(added,item.file) then
        table.insert(added, item.file) -- whether can/cannot parse, already tried
        local ok, err = pcall(reload_and_reparse_file,item)
        if not ok then
          table.insert(cannot_parse,item)
        end
      end
    else
      table.insert(cannot_parse,item)
    end

    ::continue::
  end
  return cannot_parse
end


local parse = function(input)
  -- local parse_p = profiler('parse')
  watch_input(input)
  local output = {}
  -- corresponding to the input, only copy a sub-set of parse_results(current input), don't send all of them back for performance
  local cannot_parse = langtree_input(input)
  local fail_parse_keys = {}
  for i,item in ipairs(cannot_parse) do
    reset_file_data(item.file,-1,-1,'null')
    set_file_pos_result(item.file,item.position,'file_error')
    if not output[item.file] then output[item.file] = {} end
    output[item.file].bufnr = -1
    output[item.file].filetick = -1
    output[item.file].filetype = 'null'
    output[item.file][make_pos_key(item.position)] = 'eror'
    table.insert(fail_parse_keys,make_file_pos_key(item.file,item.position))
  end
  -- log('fail_parse_files',fail_parse_keys)

  for _,item in ipairs(input) do
    local file_pos_key = make_file_pos_key(item.file,item.position)
    if not vim.tbl_contains(fail_parse_keys, file_pos_key) then
      local ok,value = pcall(update_parse_results,item)
      if not ok then
        -- log("cannot parse item",value)
        set_file_pos_result(item.file,item.position,'parse_error')
      else
        set_file_pos_result(item.file,item.position,value)
      end

      if not output[item.file] then output[item.file] = {} end
      output[item.file].bufnr = parse_results[item.file].bufnr
      output[item.file].filetick = parse_results[item.file].filetick
      output[item.file].filetype = parse_results[item.file].filetype
      output[item.file][make_pos_key(item.position)] = get_file_pos_result(item.file,item.position)
    end
  end
  -- parse_p.finish()
  return output
end

------------------------- test functions
local fake_stdin_from_t = function(t)
  t = coding_util.encoding(t,123)
  return {table.concat(t,'\n')}
end

M.test = function ()
  log = vim.print
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.fn.expand('%:p')
  local filetick = 0
  local filetype = vim.api.nvim_buf_get_option(buf,'ft')
  local cursor = vim.api.nvim_win_get_cursor(0)
  local curr = {
    file = file,
    filetick = filetick,
    filetype = filetype,
    position = {cursor[1]-1,cursor[2]}
  }

  local input = R('scratch.two_input_t')
  input[#input+1] = curr
  local t = fake_stdin_from_t(input)
  -- log('test input: ',type(t), #t, t[1])
  M.handle(nil,t,nil)
end

M.cb = function (data,id,_,event)
  for tick,input in pairs(data) do
    local ret = parse(input)
    if id and event=='stdin' then
      vim.fn.chansend(id,coding_util.encoding(ret,tick))
    end
  end
end

M.handle = coding_util.wrap_for_stdin_handle(M.cb)

-------------------------- real remote functions
M.wait_stdin = function ()
  vim.fn.stdioopen({on_stdin = M.handle})
end

return M
