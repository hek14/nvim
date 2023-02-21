local install_helper = function()
  print('Step 1. download pylance from my own BaiDuDisk or install in vscode ONLY FOR: 2023-2-30 version')
  print('Step 2. mv /path/to/download/ms-python.vscode-pylance-2023.2.30 ~/.config/nvim/bin')
  print('Step 3. use prettier to format it `~/.local/share/nvim/mason/bin/prettier --write ~/.config/nvim/bin/ms-python.vscode-pylance-2023.2.30/dist/server.bundle.js`')
  print('Step 4. insert `return !0x0;` at line 20699, which means after `const _0x2500a7 = _0x415341;` and before `for (const _0x411f95 of [`')
  print('Step 5. run `node ~/.config/nvim/bin/ms-python.vscode-pylance-2023.2.30/dist/server.bundle.js --stdio` to check or this script again')
  print('Step 6. create a file called pylance-langserver under `~/.config/nvim/bin` (should be already there)')
  print('Step 7. write the following lines: ')
  print([[
#!/usr/bin/env node
/* eslint-disable @typescript-eslint/ban-ts-comment */
// @ts-nocheck

// Stash the base directory into a global variable.
global.__rootDirectory = __dirname + '/ms-python.vscode-pylance-2023.2.30/dist';

require('./ms-python.vscode-pylance-2023.2.30/dist/server.bundle.js');
]])
  print('chmod +x ~/.config/nvim/bin/pylance-langserver')
end

local found_exe = vim.fn.executable('pylance-langserver')  
if found_exe == 0 then
  install_helper()
  error("you should have a pylance-langserver executable")
end

local uv = vim.loop
local function safe_close(handle)
  if not uv.is_closing(handle) then
    uv.close(handle)
  end
end
local stdout = uv.new_pipe(false)
local stderr = uv.new_pipe(false)
local stdin = uv.new_pipe(false)
local handle
local pid_or_err
local opts = {
  args = {},
  stdio = { stdin, stdout, stderr }
}
local execute_ok = true

handle, pid_or_err = uv.spawn("pylance-langserver", opts, function(code)
  uv.read_stop(stdout)
  uv.read_stop(stderr)
  safe_close(handle)
  safe_close(stdout)
  safe_close(stderr)
  safe_close(stdin)
  vim.schedule(function ()
    vim.notify(string.format("pylance is ok: %s",execute_ok))
  end)
  if not execute_ok then
    install_helper()
    error("pylance is broken")
  end
end)
-- uv.read_start(stdout, function(err, data)
-- end)
uv.read_start(stderr, function(err, data)
  if data and (string.match(data,'license') or string.match(data,'stand-alone')) then
    print(data)
    execute_ok = false
  end
end)
