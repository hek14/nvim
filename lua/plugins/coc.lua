local M = {
  dir = '~/contrib/coc.nvim',
  branch = 'master',
  event = 'VimEnter',
  dependencies = {
    "fannheyward/telescope-coc.nvim",
    config = function()
      require("telescope").setup({
        extensions = {
          coc = {
            theme = 'ivy',
            prefer_locations = true, -- always use Telescope locations to preview definitions/declarations/implementations etc
          }
        },
      })
      require('telescope').load_extension('coc')
    end
  },
  build = 'yarn install --frozen-lockfile',
}

M.config = function()
  -- vim.cmd [[hi! link CocMenuSel Visual]]
  -- Some servers have issues with backup files, see #649
  vim.opt.backup = false
  vim.opt.writebackup = false
  local keyset = vim.keymap.set
  local opts = {silent = true, noremap = true, expr = true, replace_keycodes = false}
  -- Autocomplete
  function _G.check_back_space()
    local col = vim.fn.col('.') - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
  end
  keyset("i", "<TAB>", [[coc#pum#visible() ? coc#pum#next(1) : v:lua.check_back_space() ? "<TAB>" : coc#refresh()]], opts)
  keyset("i", "<S-TAB>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]], opts)
  keyset("i", "<C-n>", [[coc#pum#visible() ? coc#pum#next(1) : "\<C-n>"]], opts)
  keyset("i", "<C-p>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-p>"]], opts)
  keyset("i", "<cr>", [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]], opts)
  keyset("i", "<c-,>", "coc#refresh()", {silent = true, expr = true})

  -- Highlight the symbol and its references on a CursorHold event(cursor is idle)
  vim.api.nvim_create_augroup("CocGroup", {})
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = "CocGroup",
    command = "hi! link CocMenuSel Visual",
  })
end

return M
