# nvim's good shell companion/dependencies
- nodejs(node+npm) >= 16, required by Lsp
- pyright
- lua-language-server
- clangd
- ripgrep
- fdfind
- z/zoxide
- fzf
- lazygit
- [clippy](https://bitpowder.com:2443/bvgastel/clippy)
- prettier: format tools

# I don't use Mason.nvim, but I use its website for searching tools
- https://mason-registry.dev/registry/list
- https://github.com/williamboman/mason-lspconfig.nvim?tab=readme-ov-file#available-lsp-servers

# vim.keymap.set `expr` & `silent`
如果是想把一个key映射成包含`<Left>`, `<CR>`等特殊含义的一连串key, "just as I typed them"的话, 就需要使用`expr = false`, `silent = false`
```lua
vim.keymap.set("n", ",w", [[/\<\><Left><Left>]], {expr = false, silent = false})
```
- `expr`: 如果映射的那个字符串是一个函数, 真正映射的keymap是`eval()`那个函数得到的结果, 那么`expr=true`
- `silent`: 在这里, 我们希望弹出窗口供我们输入, 所以`silent=false`

# lua-async-await理解
- repo: https://github.com/ms-jpq/lua-async-await
- 作用: 实现python的`async await`关键词, 让libuv中常见的异步operation同步化, 同时仍然允许concurrent并发
- `await([some awaitable defined by async])`作用是同步一个async op的结果, 它会pause当前的coroutine, 但是当前main threading有多个coroutine, 因此使用await不会block整个nvim编辑器!
- 例如lsp_request, 如果我们想在拿到异步request的结果执行一段代码, 我们怎么办呢? 以前我们需要将这段代码写在callback函数里面, 但是有了`async await`之后, 我们只需要做如下修改:
将其wrap成一个sync op, 然后`local result = await(wrapped)`
```lua
local function lsp_request(callback)
  vim.lsp.buf_request(buf, "textDocument/references", params, function(err, result, ctx, config) -- 这个callback的signature原本是怎样就怎样写, 根据具体的async op的规定来
    if(err or result == nil or vim.tbl_isempty(result)) then
      callback("error") -- 相当于yield "error"
    else
      callback(result) -- 相当于yield result
    end
  end)
end
local wrapped = a.wrap(lsp_request)

in Another async def:
  ...
  local result = await(wrapped)
  ...
```
- 具体解析: 见 ~/.config/nvim/async_tutorial.lua

# in Lazy.nvim, how to load a plugin after/before another plugin
一个实际的example: 在darkplus theme load之后再去加载windline statusline插件, 不然其颜色不对. 方法是
首先去掉darkplus加载的任何`event`, `cmd`, `key`等lazy load的方式, 然后在darkplus的`config`中去加载windline:
```lua
local darkplus = {
  "LunarVim/darkplus.nvim",
  event = 'VeryLazy',
  priority = 999,
  config = function ()
    vim.cmd("colorscheme darkplus")
    override_hl()
    -- NOTE: 这就是:Lazy load xxx所调用的api:
    require("lazy").load({plugins = {"windline.nvim", "bufferline.nvim"}})
  end
}
```
To load A after B:
```lua
local B = {
    "author_B/repo_B",
    event = "BufRead", -- NOTE: the trigger of B
    config = function()
        require("A") -- NOTE: this is what you want! Put this in `config`, require A will load the package A for the first time!
    end
}
```
To load A before B:
```lua
local B = {
    "author_B/repo_B",
    event = "BufRead", -- NOTE: the trigger of B
    init = function()
        require("A") -- NOTE: this is what you want! Put this in `init`, A will be loaded before B is loaded
    end
}
```

# solve treesitter errors when update nvim
- treesitter_query parse error at xxx structure
删除`/usr/local/lib/nvim/parser/query.so`
然后`TSInstall query`
- `:help xxx`打开文档时vimdoc error
方法也是删除`/usr/local/lib/nvim/parser/vimdoc.so`
然后`TSInstall vimdoc`

# in nvim's terminal, the recipe for edit files in current nvim instance
`nvr --remote FILE_NAME`

# the recipe for running shell command async in neovim
```lua
local M = require("scratch.job_util")
local t = M.new([[rsync -avrzh qingdao:~/codes_med33/IMWUT2022/tmp/ /Users/hk/mnt/qingdao/codes_med33/IMWUT2022/tmp/]], function(out, err)
  if out then
    vim.notify(vim.inspect(out), vim.log.levels.WARN)
    M.dump_to_file("~/log", out)
  else
    vim.notify("No stdout", vim.log.levels.ERROR)
  end
  if err then
    vim.notify(string.format("Error: %s", vim.inspect(err)), vim.log.levels.ERROR)
    M.dump_to_file("~/log2", err)
  end
end)
t:run()
```

# minimal config to reproduce an issue
https://github.com/folke/noice.nvim/wiki/Minimal-%60init.lua%60-to-Reproduce-an-Issue

# rust installation
- install rustup:
有了rustup, 其他rust相关工具都能用它下载;
`nix-env -iA nixpkgs.rustup`
- switch to nightly
用nightly, stable会有很多问题
`rustup install nightly`
`rustup default nightly`
然后用rustup去安装rustc, cargo

# coroutine wrapped function just failed silently!!!
coroutine中出了错不会报错...所以写完要拿出来单独运行check一下正确性
```lua
local co = coroutine
local thread = co.create(function()
  local color = vim.api.nvim_get_hl_by_name('diffAdded',true) -- NOTE: diffadded is not defined, however run this in coroutine just failed silently
  vim.print(color)
  co.yield(color)
end)
local val = co.resume(thread)
print(co.status(thread))

-- NOTE:单独check coroutine内部wrap的代码的正确性:
-- local color = vim.api.nvim_get_hl_by_name('diffAdded',true) -- NOTE: diffadded is not defined, so run this in main will spawn an error
-- vim.print(color)
```

# record debugging bufferline.nvim
遇到一个bug: 使用dap, 结束debug之后, insert mode下type anything, 自动回到normal mode
最终发现是bufferline.nvim挂的autocmd的问题. 解决过程:
1. `nvim -V9nvim.log` 这样会set verbose=9, 并保存到nvim.log
2. 在出现bug之前(dap结束之前), 一直`echo > nvim.log`去清空这个文件
3. 出现bug之后打开这个文件搜索“insert”找到可能引发bug的若干插件, 一个一个去掉看bug消失了没
4. Extra tip: 出现bug时, `:Lazy`看看现在没加载哪些插件, 它们一定没问题 

# important tips for raise keyboard response speed/make keypress snappier
https://apple.stackexchange.com/questions/10467/how-to-increase-keyboard-key-repeat-rate-on-os-x
The step values that correspond to the sliders on the GUI are as follow (lower equals faster):
KeyRepeat: 120, 90, 60, 30, 12, 6, 2
InitialKeyRepeat: 120, 94, 68, 35, 25, 15
On Mac
```shell
defaults write -g ApplePressAndHoldEnabled -bool false; defaults write NSGlobalDomain KeyRepeat -int 1; defaults write NSGlobalDomain InitialKeyRepeat -int 10
```
you should *restart* to make this work.
On Linux:
```shell
xset r rate 210 40
```

# check default keymap
`help index`

# font website
https://www.programmingfonts.org
https://www.codingfont.com/
https://www.nerdfonts.com/font-downloads

# install neovim from scratch
1. install nvim nightly
  1.1 wget -c nvim-macos.tar.gz (from the github release page)
  1.2 xattr -c nvim-macos.tar.gz
  1.3 extract xxx.tar.gz
  1.4 cd nvim-xxx
  1.5 rm -rf /usr/local/bin/nvim /usr/local/lib/nvim /usr/local/share/nvim
  1.6 for mac-os:
      cp bin/nvim /usr/local/bin/
      cp -r share/nvim /usr/local/share/
      cp -r lib/nvim /usr/local/lib/
  1.7 for linux:
      cp bin/nvim /usr/bin/
      cp -r share/nvim /usr/share/
      cp -r lib/nvim /usr/lib/
要注意的是: mac-os不能使用从chrome浏览器点击下载nvim-macos.tar.gz的方式
使用这种方式安装的nvim会经常报开发者不受信任的错误.
mac上下载的正确方式是从safari或者直接复制链接之后wget.
2. remove the ~/.cache/nvim and ~/.local/share/nvim
3. remove ~/.config/nvim/plugin/packer_compiled.lua
4. install node>12.0 (for ubuntu, you need to install manually)
  4.1. curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh
  4.2. sudo bash nodesource_setup.sh
  4.3. sudo apt-get update && sudo apt install nodejs
  4.4. node -v # check the version 

# referred dotfiles:
- https://github.com/tjdevries/config.nvim: TJ
- https://github.com/coffebar/dotfiles: nice rsync plugin, transfer.nvim
- https://github.com/omerxx/dotfiles: https://www.youtube.com/@devopstoolbox
- https://github.com/dlvhdr/dotfiles: 很好看的tmux+kitty配置 https://www.youtube.com/@JoshMedeski
- https://github.com/HCY-ASLEEP/NVIM-Config: 没有插件的nvim config
- https://github.com/vsedov/nvim: really hacky about pylance config
- https://github.com/max397574/omega-nvim: only hack pylance!!!
- https://github.com/abzcoding/lvim: a lot of things to refer
- https://github.com/RRethy/dotfiles/tree/master/nvim: the author of vim-illuminate
- https://github.com/lucasvianav/nvim: nice hacking about lspconfig handlers
- https://github.com/leaxoy/dotfiles/tree/main/.config/nvim
- https://github.com/glepnir/nvim
- https://github.com/ziontee113/nvim-config: nice youtube vlog
- https://github.com/s1n7ax/dotnvim: Power of LuaSnip with TreeSitter in Neovim
- https://github.com/folke/dot/tree/master/config/nvim
- https://github.com/williamboman/nvim-config: the author of mason.nvim
- https://github.com/adoyle-h
- https://github.com/JoosepAlviste/dotfiles: nice customizaion about telescope live_grep
- https://github.com/joshmedeski/dotfiles: yabai,skhd,alacritty,tmux
- https://github.com/askfiy/nvim: [bilibili](https://space.bilibili.com/35183144)
- https://github.com/zbirenbaum/zvim
- https://github.com/jmbuhr/quarto-nvim-kickstarter
- https://github.com/JuanZoran/myVimrc
- https://github.com/ray-x/nvim & http://rayx.me/ : author of navigator.lua
- https://github.com/Fireond/Neovim-config: for latex writting 
- https://github.com/ibhagwan/nvim-lua: the author of fzf-lua
- https://github.com/ibhagwan/dots: documented about configs, picky about plugins
- https://github.com/XXiaoA/nvimrc

# referred plugins
- https://github.com/nosduco/remote-sshfs.nvim
- https://github.com/anuvyklack/hydra.nvim: emacs hydra alternative for nvim! finally here
- https://github.com/ziontee113/syntax-tree-surfer: navigater/swap based on syntax tree(powered by treesitter)
- https://github.com/stevearc/overseer.nvim: yet another task manager
- https://github.com/cshuaimin/ssr.nvim: Structural search and replace for Neovim
- https://github.com/mg979/vim-visual-multi: multi-cursor plugin
- https://github.com/stevearc/oil.nvim
- https://github.com/google/executor.nvim

# referred resources
- jesse19skelton
https://www.youtube.com/@jesse19skelton -- nice videos about karabiner and  yabai [his github]()
https://www.notion.so/Yabai-8da3b829872d432fac43181b7ff628fc
- s1n7ax
https://www.youtube.com/@s1n7ax/videos
- yukiUthman
https://www.youtube.com/@yukiuthman8358
https://www.youtube.com/watch?v=W8Mq--dqNow&ab_channel=YukiUthman : nice video about new_work threading!!!
https://www.youtube.com/playlist?list=PLOe6AggsTaVvsguiM_LAbdkm7dFCxYxe3
- Andrew Courter
https://www.youtube.com/@ascourter

# Config pyright/pylance stubs
Opencv see:
- https://github.com/opencv/opencv/issues/14590
- https://github.com/bschnurr/python-type-stubs
- https://github.com/microsoft/python-type-stubs
第一种方法: 将pyi文件下载到对应环境对应module的路径下, 但是每一个环境每一个module都需要单独下载, 很麻烦, 推荐下一个方法
```shell
curl -sSL https://raw.githubusercontent.com/bschnurr/python-type-stubs/add-opencv/cv2/__init__.pyi \
  -o $(python -c 'import cv2, os; print(os.path.dirname(cv2.__file__))')/__init__.pyi
```
第二种方法: `git clone --depth=1 https://github.com/microsoft/python-type-stubs.git`到`~/.config/nvim/bin/python/python-type-stubs` 
然后配置 `python.analysis.extraPaths`:
- nvim: 见`~/.config/nvim/lua/plugins/lsp/pyright_config.lua`
- vscode: 
```json
{
    "python.analysis.extraPaths": [
        "/Users/hk/.config/nvim/bin/python/python-type-stubs/stubs"
    ]
}
```

# fillchars: change fold/endOfBuffer appearance

# inspecting options and variables
instead of using message buffer, just `:put =bufnr()`, `put =@"` or insert mode: `CTRL_R=bufnr()`

# keymap fix for neovim in kitty/alacritty:
1. video: https://www.youtube.com/watch?v=lHBD6pdJ-Ng
2. config: https://github.com/ziontee113/yt-tutorials/tree/nvim_key_combos_in_alacritty_and_kitty
3. http://www.leonerd.org.uk/hacks/fixterms/
4. https://en.wikipedia.org/wiki/List_of_Unicode_characters

# nvim -V1
`:verbose map m` don't work in normal case for mappings defined in lua, you should start nvim using `nvim -V1`

# window ID and window number
`winid` is unique and not changed, 通过`vim.api.nvim_get_current_win()`得到. It's valid across tabs. Manipulate window should use win-ID more because it's unique.
`winnr` 只是tab内部的一个相对ID, 会随着布局的变化而变化. `wincmd` can prefixed with window number.
Convert between them:
`win_id2win`
relations with bufnr:
`winbufnr` and `bufwinnr`

# find what highlight is used undercursor
`:Redir lua =vim.inspect_pos()`

# check if a program is able to find in nvim
`echo exepath('python')`
`echo executable('clippy')`

# vim.schedule 陷阱/值得注意的点
```lua
local map = {}
for i,t in ipairs(tt) do
  local t 
  vim.schedule(function()
    -- do something to t
    t_proc = process(t)
    map[t] = t_proc
  end)
  if map[t] then
    -- do something to proc_t
    -- THIS IS WRONG!!!因为schedule相当于async, 上述代码map在callback中赋值, 而callback不会立马执行
  end
end
```
上面的代码中, 我们想遍历所有的t, 并利用一个vim.schedule delay处理: 本意是想快速的结束对于tt table的遍历. 
但是这样不work, 因为vim.schedule 会把process(t)的过程delay到for循环后面. 这样没有一个t会在这个for循环中被处理.

# closure usage
why using closure? -- enclose some state
closure can be seen as some kind of `function instantiate`, 因为利用closure return的function,
除了它本身的输入参数之外, 还将closure的variable作为state. 这样可以在wrapper调用的时候存储一些信息.
可以认为是这个函数的实例化.
closure有一个妙用, 比方说一个callback function 调用方固定了其输入参数只有一个: bufnr
但是我想传入其他任意的参数怎么办呢? 方法是利用closure wrapper
来自 ~/.local/share/nvim/lazy/telescope.nvim/lua/telescope/builtin/__lsp.lua:
```lua
local function get_workspace_symbols_requester(bufnr, opts)
  local cancel = function() end
  --  bufnr, opts, cancel are the enclosed states of the returned function
  return function(prompt)
    local tx, rx = channel.oneshot()
    cancel()
    _, cancel = vim.lsp.buf_request(bufnr, "workspace/symbol", { query = prompt }, tx)
    -- Handle 0.5 / 0.5.1 handler situation
    local err, res = rx()
    assert(not err, err)
    local locations = vim.lsp.util.symbols_to_items(res or {}, bufnr) or {}
    if not vim.tbl_isempty(locations) then
      locations = utils.filter_symbols(locations, opts) or {}
    end
    return locations
  end
end
get_workspace_symbols_requester(0,opts) -- to get a new cb
```

# callback的执行环境
main thread(或者process) new了一个新的thread(或者spawn出去一个新的process),并指定其在结束时call function cb,那么这个cb就是所谓的callback.
callback执行环境是: main thread(or process)
怎么去建模这件事情呢: `||`脑子里开始只有一条主线, 然后fork出去一条并行的线(child thread/process), 某时再交汇回来, 主线交叉的那个点就是callback function执行的点
(当然, 对于vim这类有loop的程序而言, 这个点可能暂时不安全, 那么会schedule cb's execution later) 

# coroutine and stack
```lua
local A = coroutine.create(function()
  coroutine.resume(B)
end)
local B = coroutine.create(function()
  coroutine.yield(3)
end)
上述代码中：A是caller，B是callee
```
coroutine的特点: 不管callee中函数栈多深，co.yield(val)的val值始终是yield给调用`coroutine.resume`的那个caller.
caller和callee的关系和栈没关系！
此时函数栈可以flatten：想象把函数中的代码全部copy出来写到callee中。
yield之后, suspended的这个context会保存state: 当前的位置(即便是多层的函数调用),别的context再resume它的时候,
它将直接从这个调用位置开始
'yield'对应的是coroutine, 值直接给co.resume的caller, `return`对应的是栈, 值给调用它的函数
想象这么一幅图: 两条生产线——两个coroutine, 每一个生产线从前到后有若干箱子从大到小——它们就是栈
co.yield/resume 是直接从一条生产线跳到另外一条去换context干活, 而栈是在这条支线上做完直接扔掉一个箱子,
把结果return给它的上层(仍在这条产线/context/coroutine上).
协程是同一个线程内部的切换context, 不是多线程, 不可能两个产线同时在做
(可以想象成, 不管咋切换, 干活的人还是一个人)

# no-wait map
When defining a buffer-local mapping for "," there may be a global mapping
that starts with ",".  Then you need to type another character for Vim to know
whether to use the "," mapping or the longer one.  To avoid this add the
<nowait> argument.  Then the mapping will be used when it matches, Vim does
not wait for more characters to be typed.  However, if the characters were
already typed they are used.

# termopen and chansend
首先理解一下为什么termopen返回值会是一个channel-ID
因为terminal在nvim中本质上就是一个buffer, 并不是真正的terminal,
`:term` 打开一个terminal之后通过ps aux可以看到一个新的zsh进程.
它本质上会spawn一个外部进程, 而这个buffer的作用就是send stdin, read stdout. 
在一个terminal buffer `lua =vim.b.terminal_job_id` 可以看到它的channel-ID,
通过`lua =vim.b.terminal_job_pid` 可以看到它的pid.
example:
1. `:terminal`
2. focus into that buffer and `:lua =vim.b.terminal_job_id` -> channel-ID
3. send something: `lua vim.fn.chansend(channel-ID,{'python\r\n'})`

# vim.wait is not the same with vim.loop.sleep !!!
vim.wait可以sync scheduled tasks, 有点类似于yield, 从当前context抽离, 从而回到main loop, 让main loop去处理task queue中已经scheduled的其他task, 起到allow other events to process的作用.
vim.loop.sleep会block整个editor, 我们从不会使用vim.loop.sleep
把握一个原则: `vim.schedule`和`vim.defer_fn`都是async operation, scheduled的function相当于一个callback, 都会等待当前的context完全结束才有可能执行, 当前context只是负责挂一个钩子
## example 1
```lua
vim.defer_fn(function () -- 这个function变成一个task放到main_loop的queue中了
  print('2',vim.loop.now()) 
end,1000) -- tell main loop to schedule a task in future
print('1',vim.loop.now())
vim.wait(3000,function () -- block current context, yield回到main_loop
  -- then main loop will check other contexts
  -- one of these contexts is execute scheduled/due tasks at current timestamp
  -- the above task is due, so it will be executed
  return false
end) 
print('3',vim.loop.now())
-- the result is: 1 2 3
```
## example 2
use vim.wait to sync uv.fs_read
```lua
local uv = vim.loop
print('start read at: ',vim.loop.now())
uv.fs_open('/home/heke/codes_med33/Phase_Correlation/test_rotate.py', 'r', 438, function(_,fd)
  if fd ~= nil then
    uv.fs_fstat(fd, function(_, stat)
      if stat ~= nil then
        uv.fs_read(fd, stat.size, -1, function(_, data)
          uv.fs_close(fd, function(_, _) end)
          print('fs_read finish at: ',vim.loop.now())
          vim.print(data)
        end)
      end
    end)
  end
end)
print('main context continue, before wait',vim.loop.now())
vim.wait(5,function ()
  return false
end)
print('after wait: ',vim.loop.now())
```
## example 3: fix project.nvim load problem in lazy
在lazy.nvim中, 如果指定一个plugin是通过`keys = {{',x',function() end}}`方式加载,
那么首次加载时真实发生的事情是: 首先加载该插件, 然后run它的`config = function() xxx end`
最后run刚才keys中`,x`指定的那个function, 后续所有的`,x`则不会再运行config部分.
问题是有一些插件在它们的`require("xxx").setup()`中会使用`vim.schedule`, 那么奇怪的事情会
发生: 第一次`,x`会失效, 这是因为: 第一次加载时, `config = function() end` 和
`,x`指定的那个函数被连着运行, 当成一个context, 而config部分调用的setup被当成了deferred
task, 它会在keys部分运行完之后, 即整个context结束之后才能开始运行. 
此时需要`vim.wait`放在config中来插在config和keys中间, 让main loop 暂时config部分,
把刚才`require('xxx').setup`这个scheduled task做完.再回到config -> keys.
我写了一个testplugin('~/contrib/testplugin') 来方便展示. 困扰很久的`project.nvim` lazy load
的问题也是这么解决的(commit SHA: 5ab3d7edf2052324071609724309403e61e91882)

# get the last changed/yanked position
```lua
local pos1 = vim.fn.getpos "'["
local pos2 = vim.fn.getpos "']"
```

# to understand plenary async
demo code: `~/.config/nvim/lua/scratch/test_plenary_async.lua`
## async.wrap
```lua
M.wrap = function(func, argc)
  local function leaf(...)
    local nargs = select("#", ...)
    if nargs == argc then
      return func(...)
    else
      return co.yield(func, argc, ...)
    end
  end
  return leaf
end
```
这里将被wrap的function co.yield 出去了, 就要提到对于function的理解了:
A function is just a chunk of codes/logic/statements about how to do something, 
将function看成是一种特殊的callable data就行了
那么这个 co.yield 的含义就明显了: 
call leaf() will actually do nothing in this coroutine, 
只是将 func(how to do it), argc(func所需参数个数), ...(调用的具体参数) yield出去,
让主coroutine拿到, 至于拿到之后怎么处理那是外部协程的事情.
## async.void and async.run (execute function)
```lua
local execute = function(async_function, callback, ...)
  local thread = co.create(async_function)
  local step
  step = function(...)
    callback_or_next(step, thread, callback, co.resume(thread, ...))
  end
  step(...)
end
M.void = function(func)
  return function(...)
    execute(func, nil, ...)
  end
end
```
```lua
local wrapped = a.wrap(function(inc, callback)
  stat = stat + inc
  callback()
end, 2)
local voided = a.void(function(arg)
  wrapped(1)
  wrapped(2)
  wrapped(3)
  stat = stat + 1
  saved_arg = arg
end)
voided "hello"
```
如何理解这段代码呢? -- 理解代码的最好方式就是用自己的方式改写, 改写的方式可以是将一些表达提取出来
单独弄成变量. 例如:
```lua
local voided = a.void(function(arg)...)
M.void = function(func)
  local first_arg = func
  return function(...) -- closure, this returned function has state: `first_arg` 
    execute(first_arg,nil,...)
  end
end
```
这里的
```lua
function(arg)
  wrapped(1)
  wrapped(2)
  wrapped(3)
  stat = stat + 1
  saved_arg = arg
end
```
就是我们想要创建的协程(或者说another context), execute函数是我们的主协程. 
在execute函数中, 我们首先创建了一个协程:
```lua
local thread = co.create(async_function)
```
然后定义了一个step函数. 这个step函数可以按照我的方式改写成: 
```lua
local func, argc, args = co.resume(thread,...)
callback_or_next(step, thread, callback, func, argc, args)
```
为什么? 因为这个被创建的协程里头, 真正yield的点都被async.wrap起来了
async.wrap返回的leaf函数的特点就是: 如果传入参数个数和定义这个async.wrap时的参数个数相等,
那么直接在副协程里把func给call了. 如果不等的话, 就会把func(how to do),argc(参数个数),
args(具体参数)给yield出去, 让主协程去做, 让主协程做的好处在于, func里面就能操纵主协程里面
的变量了, 例如这里wrapped里面`stat = stat + inc`, 所以本质上这个wrapped函数就是主协程的callback,
在副协程yield的时候执行.
副协程还是要继续要, 怎么做呢? 将step作为callback传给被wrap的函数的最后一个参数, 而被wrap的函数也
非常默契的在最后`callback()`了. 等同于调用step()
**函数就是一种特殊的data, 甚至可以看成是一个引用, 什么引用? 指向一块代码(开头)的引用/地址而已
call a func就是回到某一段代码的开端, 继续执行**

# how to temporally disable a autocmd
```lua
vim.opt.eventignore:append({ 'FileType' })
fn.bufload(bufnr)
--restore eventignore
vim.opt.eventignore:remove({ 'FileType' })
```

# how to debounce to avoid a function called very frequently?
可以用下面的, 也可以用telescope/debounce.lua中的
```lua
local running = false
function to_debounce()
  if not running then
    running = true -- NOTE: this is the point: set to true outside(not inside) of the timer
    local timer = vim.loop.new_timer()
    timer:start(debounce,0,vim.schedule_wrap(function()
      running = false -- NOTE:reset false, so running will remain true for `debounce`ms
    end)
  end
end
```

# defer_fn/schedule_wrap 的一个特点/使用误区
被defer_fnwrap的function执行的理论时间是: 起始时间(vim.defer_fn call的时间)+defer的量.
但是实际main loop 开始check的时候, 如果有积压的过时的deferred tasks, 它们不会再按照之前schedule的
时间执行, 而是被一股脑扔出去, 只保留先后顺序, 不再保留彼此之间的interval
这个really confusing, 但是也能理解: main loop不想欠东西, 有积压的就一并送出去
详细的例子和注释见: ~/.config/nvim/lua/scratch/defer_fn_complex.lua

# vim.fn.search('nvim')

# use vim in pipeline
- `ls -1 | nvim -`
- `nvim - <<(ls -1)`
- `nvim - <<<"here string"`
这里`nvim -`是指定nvim to read from stdin instead of reading a file.
`<<(command)` 同样的作用
而 `|` 则是重定向stdout of last command to the latter command's stdin 
`<<<"here string"`则是将一个string作为stdin

# filter -- use external program to insert text
`:help filter`
filter的standard input从motion/range/visual来, 然后将其standard output
transform到当前buffer.
- example 1: 
打开任意一个buffer, 输入以下文本, 选中, 然后`:'<,'>!python` 
```python
for i in range(0,10):
  print(f"map_{i}")
```
这个trick用来输入一些很有规律的文本时很有用
- example 2:
select the `import xxx`statements, and then `:'<,'>!sort`就能sort import语句了

# 制作comment文本框
```text
# this is a comment line
```
以上文本想变成下面:
```text
************************
# this is a comment line this
************************
```
可以这么干: 复制两遍, 然后select a line, `r*` 关键就是利用visual mode下的`r`replace

# submatch and `&`
在替换的时候, 可以:
- `s/xyz/&_list/g` 用&来替代匹配中的部分
- `s/xyz/\=submatch(0) . "_list"/g` 这里用\=submatch来进行同样的操作 

# add match pattern highlight
`:help match-highlight`
`:match Visual /pattern/`
how to clear the last highlight: 
`:match none`

# git
## git mergetool
https://gist.github.com/karenyyng/f19ff75c60f18b4b8149/e6ae1d38fb83e05c4378d8e19b014fd8975abb39#table-of-content

# show diff before save buffer
`:w !diff % -`

# getcompletion function
`vim.fn.getcompletion('lua', "command")` to get completion list, maybe useful in utils
