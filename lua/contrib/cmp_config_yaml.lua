local cmp = require "cmp"
local fmt = string.format
local debug = false
local source = {}

source.new = function()
  local json_decode = vim.fn.json_decode
  if vim.fn.has "nvim-0.6" == 1 then
    json_decode = vim.json.decode
  end
  local t = setmetatable({
    running_job_id = 0,
    max_items = 100,
    timer = vim.loop.new_timer(),
    json_decode = json_decode,
  }, { __index = source })
  if debug then
    t.debug_buffer = vim.api.nvim_create_buf(true,true)
  end
  return t
end

-- source.get_trigger_characters = function()
--   return { "." }
-- end

-- source.get_keyword_pattern = function()
    -- return "[%[.\"\']+"
    -- return [[\%(\k\|\.\)\+]]
-- end

source.complete = function(self, request, callback)
  -- NOTE: request: {context=xxx,completion_context=xxx,offset=xxx}
  local input = string.sub(request.context.cursor_before_line, request.offset - 1)
  local prefix = string.sub(request.context.cursor_before_line, 1, request.offset - 1)
  local line_before_current = request.context.cursor_before_line
  local line_after_current = request.context.cursor_after_line
  local file = nil
  local labels = {}
  local seen = {}

  local condition = vim.endswith(input, '.')
  if condition==false then
    callback({isIncomplete = true})
    return
  end

  local function json_to_keys(json) -- json is the root of a dict(converted by json)
    local stack = { { json, "" } }
    local curr_items = {}
    local start = os.clock()
    while #stack > 0 do
      local node, root = stack[#stack][1], stack[#stack][2]
      stack[#stack] = nil
      if type(node)~="table" then
        require('core.utils').log(("type node: %s: root: %s"):format(node,root))
      end
      for k, v in pairs(node) do
        local key_name = root ~= "" and string.format("%s.%s", root, k) or string.format("%s", k)
        if type(v) == "table" then
          table.insert(stack, #stack + 1, { v, key_name })
        else
          if not seen[key_name] then
            table.insert(
              curr_items,
              #curr_items + 1,
              {key_name,v}
            )
            seen[key_name] = true
          end
        end
      end
    end
    return curr_items
  end

  local function on_event(job_id, data, event)
    -- NOTE: callback function (goback to handle results)
      local depth = 0
      if event == "stdout" then
        if #data==0 then
          print('no yaml config found')
          return
        end
        local one_json = {}
        local file = nil
        for _k,line in ipairs(data) do
          if _k==#data or string.sub(line,2,6)=="FILE:" then
            -- ========== one json done
            if #one_json>0 then
              one_json = vim.tbl_filter(function (e)
                return e~="" and e~=nil
              end, one_json)
              if debug then
                vim.api.nvim_buf_set_lines(self.debug_buffer,-1,-1,false,one_json)
              end
              local ok,content = pcall(vim.fn.json_decode,one_json)
              if not ok then
                vim.print("ERROR: " .. content)
                return
              end
              local items = json_to_keys(content)
              for _,item in ipairs(items) do
                local mua = item[1]
                local value = item[2]
                if string.match(string.sub(line_before_current, #line_before_current, #line_before_current),"\"") then
                  mua = "\"" .. item[1]
                elseif string.match(string.sub(line_before_current, #line_before_current, #line_before_current),"\'") then
                  mua = "\'" .. item[1]
                elseif string.match(string.sub(line_before_current, #line_before_current, #line_before_current),".") then
                  mua = "." .. item[1]
                end
                table.insert(labels,#labels+1,{
                  label=file .. ': ' .. mua, -- the text shown in menu
                  filterText = file .. ' ' .. mua, -- the text used in filtering
                  documentation="value: " .. tostring(value) .. '\nFILE: ' .. file,
                  file=file, -- custom meta info
                  depth=depth, -- custom meta info
                  textEdit = {
                    newText = mua,
                    range = {
                      start = {
                        line = request.context.cursor.row - 1,
                        character = request.context.cursor.col - 1 - #input,
                      },
                      ['end'] = {
                      line = request.context.cursor.row - 1,
                      character = request.context.cursor.col - 1,
                    },
                  },
                },
              })
            end
            callback{items=labels,isIncomplete=true}
          end
          one_json = {}
          file = string.gsub(line,'"FILE:','')
          file = string.gsub(file,'"$','')
          depth = require('core.utils').stringSplit(file,"/")
        else
          table.insert(one_json,#one_json+1,line)
        end
      end
    end
    if event == "exit" then  -- called when the job is forced to jobstop()
        -- FIX: sort doesn't work
        -- table.sort(labels,function(k1,k2)
          --   if k1.depth~=k2.depth then
          --     return k1.depth < k2.depth
          --   elseif k1.file~=k2.file then
          --     return k1.file < k2.file
          --   else
          --     return k1.label< k2.label
          --   end
          -- end)
      callback{items=labels,isIncomplete=false}
      print(string.format("job exited, found %s items",#labels))
    end
  end
  self.timer:stop()
  self.timer:start(
    200,0,
    vim.schedule_wrap(function()
      local curr_dir = vim.fn.getcwd()
      local git_dir = string.gsub(vim.fn.system("git rev-parse --show-toplevel"),"%s+","")
      if not string.match(git_dir,"^fatal") then
        curr_dir = git_dir
      end
      if curr_dir == vim.env["HOME"] then
        return
      end
      if vim.fn.executable('yq')==0 then
        print("you should install yq: wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64; chmod +x /usr/local/bin/yq")
      end
      if vim.fn.executable('fd')==0 then
        print("you should install fdfind")
      end
      vim.fn.jobstop(self.running_job_id)
      self.running_job_id = vim.fn.jobstart([[while read var; do echo \"FILE: $var\" ; yq e -M -o=json $var ; done <<(fd --no-ignore --max-depth 3 '\.yaml' | sort)]], {
        on_stderr = on_event,
        on_stdout = on_event,
        on_exit = on_event,
        stdout_buffered = true,
        cwd = request.option.cwd or curr_dir,
      })
    end
    )
  )
end

return source
