local utils = require "core.utils"

local config = utils.load_config()
local map_wrapper = utils.map

local maps = config.mappings
local plugin_maps = maps.plugins
local terminal_options = config.options.terminal

local cmd = vim.cmd

-- This is a wrapper function made to disable a plugin mapping from chadrc
-- If keys are nil, false or empty string, then the mapping will be not applied
-- Useful when one wants to use that keymap for any other purpose
local map = function(...)
  local keys = select(2, ...)
  if not keys or keys == "" then
    return
  end
  map_wrapper(...)
end

local M = {}

-- these mappings will only be called during initialization
M.general = function()
  local colemak = function ()
    local lhs = "neilukj"
    local rhs = "jkluine"
    local modes = {"n", "x", "o"}
    local opt = {silent = true, noremap = true}
    for i = 1, #lhs do
      local colemak = lhs:sub(i, i)
      local qwerty = rhs:sub(i, i)
      for _, mode in ipairs(modes) do
        vim.api.nvim_set_keymap(mode, colemak, qwerty, opt)
        vim.api.nvim_set_keymap(mode, vim.fn.toupper(colemak),
          vim.fn.toupper(qwerty), opt)
        if i < 4 then -- for direction keys
          vim.api.nvim_set_keymap(mode, "<C-w>" .. colemak, "<C-w>" .. qwerty,
            opt)
          vim.api.nvim_set_keymap(mode, "<C-w><C-" .. colemak .. ">",
            "<C-w><C-" .. qwerty .. ">", opt)
        end
      end
    end
  end

  local function non_config_mappings()
    -- Don't copy the replaced text after pasting in visual mode
    map_wrapper("v", "p", "p:let @+=@0<CR>")

    -- Allow moving the cursor through wrapped lines with j, k, <Up> and <Down>
    -- http://www.reddit.com/r/vim/comments/2k4cbr/problem_with_gj_and_gk/
    -- empty mode is same as using :map
    -- also don't use g[j|k] when in operator pending mode, so it doesn't alter d, y or c behaviour
    map_wrapper({ "n", "x", "o" }, "j", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', { expr = true })
    map_wrapper({ "n", "x", "o" }, "k", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', { expr = true })
    map_wrapper("", "<Down>", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', { expr = true })
    map_wrapper("", "<Up>", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', { expr = true })

    -- use ESC to turn off search highlighting
    map_wrapper("n", "<Esc>", ":noh <CR>")
    map_wrapper("i", "<C-q>",function ()
      if vim.g.cmp_enabled then
        require("cmp").close()
        vim.g.cmp_enabled = false
      else
        require('cmp').complete()
        vim.g.cmp_enabled = true
      end
    end)
  end

  local function optional_mappings()
    -- don't yank text on cut ( x )
    -- map_wrapper({ "n", "v" }, "x", '"_x')

    -- don't yank text on delete ( dd )
    -- map_wrapper({ "n", "v" }, "d", '"_d')

    -- navigation within insert mode
    local inav = maps.insert_nav
    map("i", inav.backward, "<Left>")
    map("i", inav.end_of_line, "<End>")
    map("i", inav.forward, "<Right>")
    map("i", inav.next_line, "<Down>")
    map("i", inav.prev_line, "<Up>")
    map("i", inav.beginning_of_line, "<ESC>^i")

    -- easier navigation between windows
    local wnav = maps.window_nav
    map("n", wnav.moveLeft, "<C-w>h")
    map("n", wnav.moveRight, "<C-w>l")
    map("n", wnav.moveUp, "<C-w>k")
    map("n", wnav.moveDown, "<C-w>j")

    map("n", '[g', "<Cmd>lua require('contrib.gps_hack').gps_context_parent()<CR>", {silent=false})
    map("n", ',s',require('core.utils').range_search)
    map("x", ',s',require('core.utils').range_search)
  end

  local function required_mappings()
    map("n", "<leadr>ts", [[ :keeppatterns<Bar>:%s/\s\+$//e<CR> ]] )
    cmd [[ command DeleteTrailSpace keeppatterns<Bar>%s/\s\+$//e<Bar>noh ]]
    map("n", "<space>", "<Nop>", {noremap = true, silent = true})
    map("n", "<leader>cd", [[<cmd>lua require('core.utils').smart_current_dir()<cr>]], {silent = false}) -- example to delete the buffer
    map("n", "<F1>", "<Tab>", {noremap=true}) -- because I set <Ctrl-I> to send the same escape bytes as <Home>, so <Tab>/<Ctrl-I> can be used with this keymap
    map("x", ">", ">gv", {silent = false, noremap = true})
    map("x", "<", "<gv", {silent = false, noremap = true})
    map("n", "<leader>rr", "<cmd>lua require('telescope.builtin').resume()<CR>")
    map("t", "<C-w>n", "<C-\\><C-n><C-w>j")
    map("t", "<C-w>e", "<C-\\><C-n><C-w>k")
    map("t", "<C-w>i", "<C-\\><C-n><C-w>l")
    map("t", "<S-Space>", "<Space>",{noremap=true})
    map("n", "<Up>", "5<C-w>+")
    map("n", "<Down>", "5<C-w>-")
    map("n", "<left>", "5<C-w><")
    map("n", "<right>", "5<C-w>>")
    map("n", "<Esc>", [[:noh <Bar> :lua require('core.utils').closing_float_window()<CR>]])
    map("n", "<leader>mc", "<cmd>Messages clear<CR>")
    map("n", "<leader>mm", "<cmd>Messages<CR>")
    map("n", ",t", "<Cmd>lua require('core.utils').source_curr_file()<cr>")

    map("i", "<C-n>", "<C-O>o",{noremap = true})
    map("i", "<C-e>", "<C-O>O",{noremap = true})

    map("n",'<leader>fs','<Cmd>Telescope current_buffer_fuzzy_find fuzzy=false case_mode=ignore_case<CR>')
    -- if you want to grep only in opened buffers: lua require('telescope.builtin').live_grep({grep_open_files=true})
    map("n", "N","mzJ`z")
    map("n", "k","nzzzv")
    map("n", "K","Nzzzv")
    -- swap line up and down
    map("n", "<leader>j", "<Esc>:m .+1<CR>==")
    map("n", "<leader>k", "<Esc>:m .-2<CR>==")
    map("n",'<leader>tv', ":lua require('core.utils')<CR> | :lua my_hack_undo_redo()<CR>")
    map("n", "<leader>sw", function ()
      local cword = vim.fn.expand("<cword>")
      local cmd = string.format([[:<C-u>%%s/\<%s\>//g<Left><Left>]],cword)
      return cmd
    end,{expr=true})

    map("s","A","<Esc>A")
    map("s","U","<Esc>i")

    map("n", maps.misc.close_buffer, ":lua require('core.utils').close_buffer() <CR>") -- close  buffer
    map("n", maps.misc.cp_whole_file, ":%y+ <CR>") -- copy whole file content
    map("n", maps.misc.new_buffer, ":enew <CR>") -- new buffer
    map("n", maps.misc.new_tab, ":tabnew <CR>") -- new tabs
    map("n", maps.misc.lineNR_toggle, ":set nu! <CR>")
    map("n", maps.misc.lineNR_rel_toggle, ":set rnu! <CR>") -- relative line numbers
    map("n", maps.misc.save_file, ":w <CR>") -- ctrl + s to save file

    -- terminal mappings --
    local term_maps = maps.terminal
    -- get out of terminal mode
    map("t", term_maps.esc_termmode, "<C-\\><C-n>")
    -- pick a hidden term
    map("n", term_maps.pick_term, ":Telescope terms <CR>")
    -- Open terminals
    -- TODO this opens on top of an existing vert/hori term, fixme
    -- spawns terminals
    map(
      "n",
      term_maps.spawn_horizontal,
      ":execute 15 .. 'new +terminal' | let b:term_type = 'hori' | startinsert <CR>"
    )
    map("n", term_maps.spawn_vertical, ":execute 'vnew +terminal' | let b:term_type = 'vert' | startinsert <CR>")
    map("n", term_maps.spawn_window, ":execute 'terminal' | let b:term_type = 'wind' | startinsert <CR>")

    -- terminal mappings end --

    map("c", '<C-a>','<Home>')
    map("c", '<C-e>','<End>')
    map("c", '<C-f>','<Right>')
    map("c", '<C-b>','<Left>')
    map("c", '<C-p>','<Up>')
    map("c", '<C-n>','<Down>')

    map("x", "ul", "g_o^")
    map("o", "ul", ":normal vul<CR>")
    map("x", "al", "$o0")
    map("o", "al", ":normal val<CR>")
    map("x", "u%", "GoggV")
    map("o", "u%", ":normal vu%<CR>")

    map("n",'gp',[['`[' . strpart(getregtype(), 0, 1) . '`]']], {expr=true})

    map('i','<C-x><C-l>','<Cmd>lua require("contrib.treesitter.python").fast_signature()<CR>')
    map('i','<C-x><C-g>','<Cmd>lua require("contrib.treesitter.python").fast_init_class()<CR>')

    vim.cmd([[
        function! Cabbrev(key, value) abort
        execute printf('cabbrev <expr> %s (getcmdtype() == ":" && getcmdpos() <= %d) ? %s : %s',
        \ a:key, 1+len(a:key), Single_quote(a:value), Single_quote(a:key))
        endfunction

        function! Single_quote(str) abort
        return "'" . substitute(copy(a:str), "'", "''", 'g') . "'"
        endfunction

        call Cabbrev('pi', 'PackerInstall')
        call Cabbrev('pud', 'PackerUpdate')
        call Cabbrev('pc', 'PackerCompile')
        call Cabbrev('ps', 'PackerSync')
        call Cabbrev('li', 'let i =1 \|')
        call Cabbrev('py', 'PYTHON')
        call Cabbrev('lg', 'Lazygit')
        call Cabbrev('ft', 'FloatermNew')
        xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
        function! ExecuteMacroOverVisualRange()
        echo "@".getcmdline()
        execute ":'<,'>normal @".nr2char(getchar())
        endfunction
        " " example of how to create a new hightlight:
        hi def KK_init guibg=grey guifg=blue gui=italic
        highlight TSDefinitionUsage guibg=#444444 " NOTE: highlight used in treesitter-refactor
        highlight Visual guibg=#6c6c6c
        " " example of how to set a existing hightlight:
        " " for GUI nvim(iTerm,kitty,etc.):
        " hi Search gui=italic guibg=peru guifg=wheat
        " " for terminal nvim:
        " hi Search cterm=NONE ctermfg=grey ctermbg=blue
        " " def a highlight by linking
        " hi def link Search Todo
        ]])
    -- Add Packer commands because we are not loading it at startup
    cmd "silent! command PackerClean lua require 'plugins' require('packer').clean()"
    cmd "silent! command PackerCompile lua require 'plugins' require('packer').compile()"
    cmd "silent! command PackerInstall lua require 'plugins' require('packer').install()"
    cmd "silent! command PackerStatus lua require 'plugins' require('packer').status()"
    cmd "silent! command PackerSync lua require 'plugins' require('packer').sync()"
    cmd "silent! command PackerUpdate lua require 'plugins' require('packer').update()"
  end

  non_config_mappings()
  optional_mappings()
  required_mappings()
  colemak()
end

-- below are all plugin related mappings

M.bufferline = function()
  local m = plugin_maps.bufferline

  map("n", m.next_buffer, ":BufferLineCycleNext <CR>")
  map("n", m.prev_buffer, ":BufferLineCyclePrev <CR>")
end

M.comment = function()
  local m = plugin_maps.comment.toggle
  map("n", m, ":lua require('Comment.api').toggle_current_linewise()<CR>")
  map("v", m, ":lua require('Comment.api').toggle_linewise_op(vim.fn.visualmode())<CR>")
end

M.lspconfig = function()
  local m = plugin_maps.lspconfig

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  map("n", m.declaration, "<cmd>lua vim.lsp.buf.declaration()<CR>")
  map("n", m.definition, "<cmd>lua vim.lsp.buf.definition()<CR>")
  map("n", m.hover, "<cmd>lua vim.lsp.buf.hover()<CR>")
  map("n", m.implementation, "<cmd>lua vim.lsp.buf.implementation()<CR>")
  map("n", m.signature_help, "<cmd>lua vim.lsp.buf.signature_help()<CR>")
  map("n", m.add_workspace_folder, "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>")
  map("n", m.remove_workspace_folder, "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>")
  map("n", m.list_workspace_folders, "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>")
  map("n", m.type_definition, "<cmd>lua vim.lsp.buf.type_definition()<CR>")
  map("n", m.rename, "<cmd>lua vim.lsp.buf.rename()<CR>")
  map("n", m.code_action, "<cmd>lua vim.lsp.buf.code_action()<CR>")
  map("n", m.references, "<cmd>lua vim.lsp.buf.references()<CR>")
  map("n", m.float_diagnostics, "<cmd>lua vim.diagnostic.open_float()<CR>")
  map("n", m.goto_prev, "<cmd>lua vim.diagnostic.goto_prev()<CR>")
  map("n", m.goto_next, "<cmd>lua vim.diagnostic.goto_next()<CR>")
  map("n", m.set_loclist, "<cmd>lua vim.diagnostic.setloclist()<CR>")
  map("n", m.formatting, "<cmd>lua vim.lsp.buf.formatting()<CR>")
end

M.nvimtree = function()
  map("n", plugin_maps.nvimtree.toggle, ":NvimTreeToggle <CR>")
  map("n", plugin_maps.nvimtree.focus, ":NvimTreeFocus <CR>")
end

M.telescope = function()
  local m = plugin_maps.telescope

  map("n", m.buffers, ":Telescope buffers <CR>")
  map("n", m.find_files, "<Cmd>Telescope find_files find_command=rg,--ignore-file=" .. vim.env['HOME'] .. "/.rg_ignore," .. "--no-ignore,--files<CR>")
  map("n", m.find_hiddenfiles, ":Telescope find_files follow=true no_ignore=true hidden=true <CR>")
  map("n", m.git_commits, ":Telescope git_commits <CR>")
  map("n", m.git_status, ":Telescope git_status <CR>")
  map("n", m.help_tags, ":Telescope help_tags <CR>")
  map("n", m.oldfiles, ":Telescope oldfiles <CR>")
  map("n", m.themes, ":Telescope themes <CR>")
  map("n", m.dotfiles, ":Telescope dotfiles <CR>")
end

return M
