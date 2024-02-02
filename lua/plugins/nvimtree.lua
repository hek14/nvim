local function on_attach(bufnr)
  local api = require('nvim-tree.api')
  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end
  api.config.mappings.default_on_attach(bufnr)
  require('core.utils').del_map('n','J',bufnr)
  require('core.utils').del_map('n','K',bufnr)

  require('core.utils').del_map('n','n',bufnr)
  require('core.utils').del_map('n','e',bufnr)
  require('core.utils').del_map('n','i',bufnr)
  vim.keymap.set('n', 'N', api.node.navigate.sibling.last, opts('Last Sibling'))
  vim.keymap.set('n', 'E', api.node.navigate.sibling.first, opts('First Sibling'))
end
local M = {
  "nvim-tree/nvim-tree.lua",
  enabled = false,
  cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeClose", "NvimTreeOpen"},
  keys = {
    { ",e", "<Cmd>NvimTreeToggle<CR>" },
    { ",f", "<Cmd>NvimTreeFindFileToggle<CR>" },
  },
  config = function()
    require("nvim-tree").setup({
      on_attach = on_attach,
      view = {
        width = 30,
      }
    })
  end
}

return M
