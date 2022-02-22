local cmp = require "cmp"
local source = {}

source.is_available = function()
  return true
end

function source:get_trigger_characters()
  return { "." }
end

source.new = function()
  local json_decode = vim.fn.json_decode
  if vim.fn.has "nvim-0.6" == 1 then
    json_decode = vim.json.decode
  end
  return setmetatable({
    running_job_id = 0,
    timer = vim.loop.new_timer(),
    json_decode = json_decode,
  }, { __index = source })
end

source.complete = function(self, request, callback)
  local q = string.sub(request.context.cursor_before_line, request.offset)
  local pattern = request.option.pattern or "[\\w_-]+"
  local additional_arguments = request.option.additional_arguments or ""
  local context_before = request.option.context_before or 1
  local context_after = request.option.context_after or 3
  local quote = "'"
  if vim.o.shell == "cmd.exe" then
    quote = '"'
  end
  local file = nil
  local labels = {}
  local seen = {}

  local function json_to_keys(json) -- json is the root of a dict(converted by json)
    local stack = { { json, "" } }
    local curr_items = {}
    local start = os.clock()
    while #stack > 0 do
      local node, root = stack[#stack][1], stack[#stack][2]
      stack[#stack] = nil
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
    if event == "stdout" then
      -- print("on_event: stdout, ",vim.inspect(data))
      if #data == 1 and data[1] == "" then
        return
      end
      if string.sub(data[1],1,5)=="file:" then 
        file = string.sub(data[1],6,#data[1])
      else 
        local content = vim.fn.json_decode(vim.list_slice(data,1,#data-1))
        local items = json_to_keys(content)
        for _,item in ipairs(items) do
          table.insert(labels,#labels+1,{label=item[1],documentation=item[2] .. '\n' .. file})
        end
        -- print("the labels: ",vim.inspect(labels))
        callback{items=labels,isIncomplete=true}
      end
    end
    if event == "exit" then  -- called when the job is forced to jobstop()
      callback{items=labels,isIncomplete=false}
      print("job exited")
    end
  end
  self.timer:stop()
  self.timer:start(
    50,0,
    vim.schedule_wrap(function()
      local curr_dir = vim.fn.getcwd()
      if curr_dir == vim.env["HOME"] then
        return
      end
      if vim.fn.executable('yq')==0 then
        print("you should install yq: wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64; chmod +x yq")
      end
      if vim.fn.executable('fd')==0 then
        print("you should install fdfind")
      end
      vim.fn.jobstop(self.running_job_id)
      self.running_job_id = vim.fn.jobstart("while read var; do echo \"file: $var\" ; yq e -M -o=json $var ; done <<(fd yaml)", {
        on_stderr = on_event,
        on_stdout = on_event,
        on_exit = on_event,
        cwd = request.option.cwd or vim.fn.getcwd(),
      })
    end
    )
  )
end

return source
