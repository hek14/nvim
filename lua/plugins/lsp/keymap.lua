local M = {}
local lsp_util = vim.lsp.util

function M.peek_type(cursor)
  cursor = cursor or vim.api.nvim_win_get_cursor(0)
  local def_params = vim.lsp.util.make_position_params()
  def_params.position.line = cursor[1] - 1
  def_params.position.character = cursor[2]
  local _,result = vim.lsp.buf_request(0,'textDocument/hover', def_params, function (err, result, ctx, config)
    local bufnr = vim.api.nvim_get_current_buf()
    local syntax = 'markdown'
    if err or (not result) or (not result.contents) then
      lsp_util.open_floating_preview({'Symbol type: ','Unknown'},syntax,{})
      return
    end
    local msg = result.contents.value
    vim.print('msg: ',msg)
    local curr_expr = vim.fn.expand('<cexpr>')
    local curr_word = vim.fn.expand('<cword>')
    local ok,_ = pcall(function ()
      msg = require('core.utils').stringSplit(msg,'\n')[2] -- 2nd line is what we need
      local type = string.match(msg,'^%((.+)%)$')
      if type then
        -- 2nd line only contains: (xxx), then xxx is what we need
        lsp_util.open_floating_preview({'Symbol type: ',type},syntax,{})
        return
      end

      type = string.match(msg,'(.-) ' .. curr_word) or string.match(msg,'(.-) ' .. curr_expr)
      type = string.gsub(type,'[%(%)]','') -- remove the possible parens
      if type==nil then
        lsp_util.open_floating_preview({'Symbol type: ','Unknown'},syntax,{})
      else 
        lsp_util.open_floating_preview({'Symbol type: ',type},syntax,{})
      end
    end)
    if not ok then
      lsp_util.open_floating_preview({'Symbol type: ','Unknown'},syntax,{})
    end
  end)
end


local function gotoDefinitionInVerticalSplit()
    -- Save the original handler for 'textDocument/definition'
    local original_handler = vim.lsp.handlers['textDocument/definition']

    -- Set a custom handler for 'textDocument/definition'
    vim.lsp.handlers['textDocument/definition'] = function(err, result, ctx, config)
        if err or (not result or vim.tbl_isempty(result)) then
            vim.notify("No Definition!",vim.log.levels.WARN)
            return
        end
        vim.cmd('vsplit')
        original_handler(err, result, ctx, config)
    end
    vim.lsp.buf.definition()

    vim.lsp.handlers['textDocument/definition'] = original_handler
end

-- NOTE: refer to https://github.com/lucasvianav/nvim
function M.show_documentation()
  if vim.tbl_contains({ 'vim', 'help' }, vim.o.filetype) then
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
    require('core.utils').map(mode,lhs,rhs,opt)
  end

  vim.api.nvim_create_user_command('FixImport',function ()
    local buf = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_active_clients({bufnr = buf})
    for id,_client in pairs(clients) do
      if _client.name~='null-ls' then
        _client.notify("workspace/didChangeConfiguration", { settings = _client.config.settings })
      end
    end
  end,{})

  buf_set_keymap('n', "<leader>dt",require('contrib.my_diagnostic').toggle_line_diagnostic)
  buf_set_keymap("n", "<leader>gd",gotoDefinitionInVerticalSplit)
  buf_set_keymap("n", "gd", vim.lsp.buf.definition)
  buf_set_keymap("n", "gk", M.peek_type)
  buf_set_keymap("n", "gD", vim.lsp.buf.declaration)
  buf_set_keymap("n", "gy", vim.lsp.buf.type_definition)
  buf_set_keymap("n", "gr", require('telescope.builtin').lsp_references)
  buf_set_keymap("n", "gt", require('telescope.builtin').lsp_document_symbols)
  buf_set_keymap("n", "<leader>gt","<cmd>Telescope lsp_dynamic_workspace_symbols<CR>")
  buf_set_keymap("n", "<leader>D","<cmd>TroubleToggle document_diagnostics<CR>")
  buf_set_keymap("n", "<leader>ca",vim.lsp.buf.code_action)
  buf_set_keymap("n", "gl",vim.diagnostic.open_float)
  buf_set_keymap("n", "[d", vim.diagnostic.goto_prev)
  buf_set_keymap("n", "]d", vim.diagnostic.goto_next)
  buf_set_keymap("n", "[r", require'illuminate'.goto_prev_reference)
  buf_set_keymap("n", "]r", require'illuminate'.goto_next_reference)
  buf_set_keymap("n", "<C-k>",vim.lsp.buf.signature_help)
  buf_set_keymap("n", "<leader>rn", vim.lsp.buf.rename)
  buf_set_keymap("n", "E", M.show_documentation)
  buf_set_keymap("n", "<leader>fm",vim.lsp.buf.format)
  buf_set_keymap('n', 'gi',vim.lsp.buf.incoming_calls)
  buf_set_keymap('n', 'go',vim.lsp.buf.outgoing_calls)
end
return M
