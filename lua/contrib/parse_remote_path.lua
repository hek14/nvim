local log = require("core.utils").log
local NAME_REGEX = '\\%([^/\\\\:\\*?<>\'"`\\|]\\)'
local PATH_REGEX = vim.regex(([[\%(\%(/PAT*[^/\\\\:\\*?<>\'"`\\| .~]\)\|\%(/\.\.\)\)*/\zePAT*$]]):gsub('PAT', NAME_REGEX))

local source = {}
source.new = function()
  return setmetatable({}, { __index = source })
end

source.get_trigger_characters = function()
  return { '/', '.' }
end

source.get_keyword_pattern = function(self, params)
  return NAME_REGEX .. '*'
end

source.complete = function(self, request, callback)
  local cursor_before_line = request.context.cursor_before_line
  local cursor_after_line = request.context.cursor_after_line
  local matched = string.match(cursor_before_line, [[["|'].+:.*/]])
  local offset = string.find(cursor_before_line, [[["|'].+:.*/]])
  if(not matched) then
    return
  end
  matched = string.sub(matched, 2)
  local host = string.sub(matched, 1, string.find(matched,":") - 1) -- exclude the "', till the :
  local prefix = string.sub(matched, string.find(matched,":") + 1)
  prefix = string.gsub(prefix, "/", "&")
  -- log("offset", offset, "col", request.context.cursor.col)
  -- log("after",cursor_after_line, "before", cursor_before_line)

  local file = string.format("~/mnt/%s/%s.path", host, prefix)
  file = vim.fn.expand(file)
  if(not vim.loop.fs_stat(file)) then
    return
  end
  local items = {}
  local append_line = function(filename)
    local f_lines = vim.fn.readfile(filename)
    for _, line in ipairs(f_lines) do
      local path = string.sub(line, string.find(line,":") + 1)
      local item = {
        label = path,
        filterText = path,
        insertText = path,
        documentation = host .. prefix,
        data = {
          newText = path .. cursor_after_line,
          range = {
            ["start"] = {line = request.context.cursor.row, character = offset},
            ["end"] = {line = request.context.cursor.row, character = offset + #path + #cursor_after_line}
          }
        }
      }
      table.insert(items, item)
    end
  end
  append_line(file)
  if #items then
    callback{items = items}
  end
end

source.resolve = function(self, completion_item, callback)
  completion_item.textEdit = completion_item.data
  callback(completion_item)
end

return source
