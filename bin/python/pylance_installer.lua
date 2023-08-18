local proxy_port = is_mac and "6666" or "9978"
local sed_path = is_mac and '/Users/hk/.local/bin/gsed' or 'sed'

local uv = vim.loop
local Job = require'plenary.job'
local script0 = [[mkdir tmp]]
local script1 = [[curl -s -c cookies.txt https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance]]
local script2 = [[curl -s https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-python/vsextensions/vscode-pylance/latest/vspackage -j -b cookies.txt --compressed --output pylance.vsix]]
local script3 = [[unzip pylance.vsix]]
local script4 = {sed_path, '-i', [[0,/\(if(\!process\[[^] ]*\]\[[^] ]*\])return\!0x\)1/ s//\10/]], 'extension/dist/server.bundle.js'}
local script5 = {'mv', vim.fn.expand("~/.config/nvim/tmp"), vim.fn.expand("~/.config/nvim/bin/python/pylance_latest")}

local todo = {script0, script1, script2, script3, script4, script5}
local function go(index)
  if(index>#todo) then
    vim.notify("all job done", vim.log.levels.INFO)
    return
  end

  local comps = todo[index]
  if type(todo[index])=="string" then
    comps = require('core.utils').stringSplit(todo[index], ' ')
  end
  vim.print(comps)
  Job:new({
    command = comps[1],
    args = vim.list_slice(comps,2),
    cwd = (index==1) and vim.fn.expand("~/.config/nvim") or vim.fn.expand("~/.config/nvim/tmp"),
    env = {
      ['http_proxy'] = string.format("http://localhost:%s",proxy_port),
      ['https_proxy'] = string.format("http://localhost:%s",proxy_port),
      ['all_proxy'] = string.format("http://localhost:%s",proxy_port),
    },
    on_exit = vim.schedule_wrap(function(j, code)
      vim.print(j:stderr_result())
      if(code~=0) then
        vim.notify(string.format("ERROR script %d",index),vim.log.levels.ERROR) 
        return
      end
      vim.notify(string.format("job %d done",index), vim.log.levels.INFO)
      go(index+1)
    end),
  }):start()
end
go(1)
