local M = {}

function M.Smart_goto_definition()
  local bufnr = vim.fn.bufnr()
  vim.cmd [[normal! m`]]
  require('contrib.pig').async_def(function()
    print('using fallback')
    require'nvim-treesitter-refactor.navigation'.goto_definition(bufnr,
    function()
      print("dumb goto")
      vim.cmd [[normal! gd]] -- dumb goto definition
    end)
  end)
end

function M.definition_in_split()
  if vim.fn.winnr('$')<4 then
    if vim.fn.winwidth(0) < 120 then
      vim.cmd[[split]]
    else
      vim.cmd[[vsplit]]
    end
  end
  if package.loaded['lspconfig']~=nil then
    vim.lsp.buf.definition() -- built-in lsp
  else
    vim.cmd [[exe "normal \<Plug>(coc-definition)"]] -- or coc
  end
end

function M.Smart_goto_next_ref(index)
  local bufnr = vim.fn.bufnr()
  vim.cmd [[normal! m`]]
  require('contrib.pig').next_lsp_reference(index, function()
    print('using fallback')
    if index > 0 then
      require"illuminate".next_reference{wrap=true}
      -- require'nvim-treesitter-refactor.navigation'.goto_next_usage()
    else
      require"illuminate".next_reference{reverse=true,wrap=true}
      -- require'nvim-treesitter-refactor.navigation'.goto_previous_usage()
    end
  end)
end

-- NOTE: refer to https://github.com/lucasvianav/nvim
function M.show_documentation()
  if vim.tbl_contains({ 'vim', 'help', 'lua' }, vim.o.filetype) then
    local has_docs = pcall(vim.api.nvim_command, 'help ' .. vim.fn.expand('<cword>'))

    if not has_docs then
      vim.lsp.buf.hover()
    end
  else
    vim.lsp.buf.hover()
  end
end


function M.setup(client,bufnr)
  local map_opts = {noremap = true, silent = true,buffer = bufnr}
  local function buf_set_keymap(mode,lhs,rhs,opt)
    opt = vim.tbl_deep_extend("force", {}, map_opts, opt or {})
    vim.keymap.set(mode,lhs,rhs,opt)
  end
  buf_set_keymap("n", "<leader>gd","<cmd>lua require('telescope.builtin').lsp_definitions()<CR>",map_opts)
  buf_set_keymap("n", "<leader>gr","<cmd>lua require('telescope.builtin').lsp_references()<CR>",map_opts)
  buf_set_keymap("n", "gd", "", {callback = M.Smart_goto_definition})
  buf_set_keymap("n", "gD", "", {callback = M.definition_in_split})
  buf_set_keymap("n", "gr","<cmd>lua require('contrib.pig').async_ref()<CR>",map_opts)
  buf_set_keymap("n", "gt","<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>",map_opts)
  buf_set_keymap("n", "<leader>gt","<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>",map_opts)
  buf_set_keymap("n", "<leader>ca","<cmd>lua require('telescope.builtin').lsp_code_actions()<CR>",map_opts)
  buf_set_keymap("n", "gl","<cmd>lua vim.diagnostic.open_float()<CR>",map_opts)
  buf_set_keymap("n", "<leader>D","<cmd>TroubleToggle document_diagnostics<CR>",map_opts)
  -- buf_set_keymap("n", "<leader>,", "<cmd>lua vim.lsp.buf.document_highlight()<CR>",map_opts)
  -- buf_set_keymap("n", "<leader>.", "<cmd>lua vim.lsp.buf.clear_references()<CR>",map_opts)
  buf_set_keymap("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>",map_opts)
  buf_set_keymap("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>",map_opts)
  -- buf_set_keymap("n", "[r", "", {callback = function()
  --   M.Smart_goto_next_ref(-1)
  -- end})
  -- buf_set_keymap("n", "]r", "", {callback = function()
  --   M.Smart_goto_next_ref(1)
  -- end})
  buf_set_keymap("n", "[r", "<cmd>lua require'illuminate'.next_reference{reverse=true,wrap=true}<CR>",map_opts)
  buf_set_keymap("n", "]r", "<cmd>lua require'illuminate'.next_reference{wrap=true}<CR>",map_opts)
  -- buf_set_keymap("n", "]r", "<cmd>lua require'nvim-treesitter-refactor.navigation'.goto_next_usage()<CR>",map_opts)
  buf_set_keymap("n", "<C-k>","<cmd>lua vim.lsp.buf.signature_help()<CR>", map_opts)
  -- buf_set_keymap("i", "<C-k>","<cmd>lua vim.lsp.buf.signature_help()<CR>", map_opts)
  buf_set_keymap("n", "<leader>rn","<cmd>lua require('contrib.pig').rename()<CR>",map_opts)
  buf_set_keymap("n", "<leader>wa","<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>",map_opts)
  buf_set_keymap("n", "<leader>wr","<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>",map_opts)
  buf_set_keymap("n", "<leader>wl","<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>",map_opts)
  buf_set_keymap("n", "K", "N", map_opts)
  buf_set_keymap("n", "E", "", {callback = M.show_documentation})
  buf_set_keymap("n", "<leader>fm","<cmd>lua vim.lsp.buf.formatting()<CR>", map_opts)
  buf_set_keymap("n", "<leader>[r","<cmd>lua require'nvim-treesitter-refactor.navigation'.goto_previous_usage()<CR>",map_opts)
  buf_set_keymap("n", "<leader>]r","<cmd>lua require'nvim-treesitter-refactor.navigation'.goto_next_usage()<CR>",map_opts)
  buf_set_keymap('n', 'gi',"<cmd>lua vim.lsp.buf.incoming_calls()<CR>",map_opts)
  buf_set_keymap('n', 'go',"<cmd>lua vim.lsp.buf.outgoing_calls()<CR>",map_opts)
end
return M
