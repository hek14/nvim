local function on_attach(bufnr)
  local api = require('nvim-tree.api')
  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end
  vim.keymap.set('n', '<C-e>', api.node.open.replace_tree_buffer, opts('Open: In Place'))
  vim.keymap.set('n', 'N', api.node.navigate.sibling.last, opts('Last Sibling'))
  vim.keymap.set('n', 'E', api.node.navigate.sibling.first, opts('First Sibling'))
  vim.keymap.set('n', 'R', api.tree.reload, opts('Refresh'))
  vim.keymap.set('n', 'r', api.fs.rename, opts('Rename'))
  vim.keymap.set('n', '<C-r>', api.fs.rename_sub, opts('Rename: Omit Filename'))
end
local M = {
  "nvim-tree/nvim-tree.lua",
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
