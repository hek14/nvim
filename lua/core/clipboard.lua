-- reference: https://github.com/neovim/neovim/pull/25872
-- https://github.com/lewis6991/dotfiles/blob/26d4b8d0983b1d94fd624781888c42f4edabc734/config/nvim/lua/lewis6991/clipboard.lua
-- https://github.com/ojroques/nvim-osc52
-- https://sspai.com/post/71018
-- https://github.com/sunaku/home/blob/master/bin/yank
-- character table string
local N = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
--- @param data string
--- @return string
local function encode_base64(data)
  local data1 = (
    data:gsub(
      '.',
      --- @param x string
      --- @return string
      function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do
          r = r .. (b % 2^i - b % 2^(i-1) > 0 and '1' or '0')
        end
        return r
      end
    )..'0000'
  )

  local data2 = data1:gsub(
    '%d%d%d?%d?%d?%d?',
    --- @param x string
    --- @return string
    function(x)
      if #x < 6 then
        return ''
      end
      local c = 0
      for i = 1, 6 do
        c = c + (x:sub(i, i) == '1' and 2^(6 - i) or 0)
      end
      return N:sub(c + 1, c + 1)
    end
  )

  local suffix = ({ '', '==', '=' })[#data%3+1]

  return data2..suffix
end

local function osc52_copy(text)
  local text_b64 = encode_base64(text)
  local osc = string.format('%s]52;c;%s%s', string.char(0x1b), text_b64, string.char(0x07))
  io.stderr:write(osc)
end

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    osc52_copy(vim.fn.getreg(vim.v.event.regname))
  end
})

-- local function paste()
--   return {
--     fn.split(fn.getreg(''), '\n'),
--     fn.getregtype('')
--   }
-- end

-- local function copy(lines, regtype)
--   osc52_copy(table.concat(lines, '\n'))
-- end

-- vim.g.clipboard = {
--   name = 'osc52',
--   copy = {
--     ["+"] = copy,
--     ["*"] = copy
--   },
--   paste = {
--     ["+"] = paste,
--     ["*"] = paste
--   },
-- }
