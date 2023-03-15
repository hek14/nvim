local watch_util = require('scratch.file_watcher')

watch_util.add_watcher('/Users/hk/server_files/qingdao/test/debug.py',function (path,time)
  print('path changed:',time)
end)

watch_util.add_watcher('/Users/hk/server_files/qingdao/test/debug.py',function (path,time)
  print('path changed:',time)
end)
