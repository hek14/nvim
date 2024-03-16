local get_layout = require("scratch.restore_layout.save_layout").get_layout
local get_split = require("scratch.restore_layout.save_layout").get_split_layout
local set_layout = require("scratch.restore_layout.restore_layout").restore

local f = string.format
local log = require('core.utils').log

_G.lru = require("contrib.lru"):new()

local group = vim.api.nvim_create_augroup("kk_restore_layout", {clear = true})

local last_split = get_split()

local last_layout = get_layout()

lru:insert_data(last_layout)

local autocmd_enabled = true

local counter = 0

vim.api.nvim_create_autocmd({"WinNew", "WinClosed"}, {
  desc = "auto save window layout",
  group = group,
  callback = function(params)
    if(not autocmd_enabled) then
      return
    end

    local cur_split = get_split()
    if(#cur_split == #last_split) then -- NOTE: only when split layout changed
      return
    end

    counter = counter + 1
    -- log(f("called %d %s %s", counter, vim.inspect(cur_split), vim.inspect(last_split)))

    last_split = cur_split
    local cur = get_layout()
    -- log(f("param: %s, cur: %s", params.event, vim.inspect(cur)))
    lru:insert_data(cur)
  end
})

vim.keymap.set("n", "<C-w>l", function()
  local count = vim.v.count
  count = count == 0 and 1 or count

  autocmd_enabled = false

  lru:visit(count + 1) -- NOTE: move the last layout to head
  local last = lru:front()
  set_layout(last)
  last_split = get_split() -- NOTE: remember to manually set this


  autocmd_enabled = true
end, { desc = "Restore last layout" })
