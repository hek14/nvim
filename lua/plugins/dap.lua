local M = {
  "mfussenegger/nvim-dap",
  dependencies = {
    "nvim-telescope/telescope-dap.nvim",
    "theHamsta/nvim-dap-virtual-text",
    "mfussenegger/nvim-dap-python",
    "rcarriga/nvim-dap-ui",
  },
}

function M.config()
  local dap = require('dap')
  local g = vim.g
  local map = require('core.utils').map
  require('dap-python').setup(vim.fn.system("which python"):gsub('\n',''),{console = 'internalConsole'})
  -- require('dap').set_log_level('INFO')
  dap.defaults.fallback.terminal_win_cmd = '80vsplit new'
  vim.fn.sign_define('DapBreakpoint', {text= '🐛', texthl='', linehl='', numhl=''})
  vim.fn.sign_define('DapBreakpointRejected', {text='🟦', texthl='', linehl='', numhl=''})
  vim.fn.sign_define('DapStopped', {text='⭐️', texthl='', linehl='', numhl=''})

  -- _G.shutDownDapSession = function()
    --   local dap = require'dap'
    --   dap.terminate()
    --   dap.disconnect( { terminateDebuggee = true })
    --   dap.close()
    -- end

    map('n', '<leader>b', ':lua require"dap".toggle_breakpoint()<CR>')
    map('n', '<leader>B', ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>")
    map('n', '<leader>lp',":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>")
    map('n', '<F12>', ':lua require"dap".step_out()<CR>')
    map('n', '<F11>', ':lua require"dap".step_into()<CR>')
    map('n', '<F10>', ':lua require"dap".step_over()<CR>')
    map('n', '<F5>', ':lua require"dap".continue()<CR>')
    map('n', '<F4>', ':lua require"dap".run_to_cursor()<CR>')
    map('n', '<F8>', ':lua require"dap".toggle_breakpoint()<CR>')
    map('n', '<leader>dn', ':lua require"dap".down()<CR>')
    map('n', '<leader>de', ':lua require"dap".up()<CR>')
    map('n', '<leader>ds', ':Telescope dap configurations<CR>')
    map('n', '<leader><F5>', 'lua require"dap".run_last()<CR>')
    -- ========== NOTE: dap.close() will not kill the debugee, it just close the nvim-dap session, while dap.disconnet() will deattach the adapter from the debugee(the program being debugged now)
    -- map('n', '<leader>dq', ':lua require"dap".close()<CR>:lua require("dapui").close()<CR>') 
    map('n', '<leader>dq', ':lua require"dap".terminate()<CR>:lua require("dapui").close()<CR>')
    map('n', '<leader>dr', ':lua require"dap".repl.toggle({},"10 split")<CR>')
    map('n', '<leader>di', ':lua require"dap.ui.widgets".hover()<CR>')
    map('n', '<leader>d?', ':lua local widgets=require"dap.ui.widgets";widgets.centered_float(widgets.scopes)<CR>')

    local function focus_hover()
      local found = nil
      for win=1,vim.fn.winnr("$") do
        local winid = vim.fn.win_getid(win)
        local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(winid))
        local config = vim.api.nvim_win_get_config(winid)
        if config['focusable'] and config["relative"] ~= ""then
          --  and bufname=='DAP Hover'
          found = win
          break
        end
      end
      return found
    end

    vim.keymap.set('n',',e',function ()
      local found_hover = focus_hover()
      if found_hover~=nil then
        return string.format([[:<C-u>%s wincmd w<CR>]],found_hover)
      else
        return [[:<C-u>lua require('dapui').eval()<Left>]]
      end
    end,{expr=true})

    vim.keymap.set('x',',e',function ()
      local found_hover = focus_hover()
      if found_hover~=nil then
        return string.format([[:<C-u>%s wincmd w<CR>]],found_hover)
      else
        return [[:<C-u>lua require('dapui').eval()<CR>]]
      end
    end,{expr=true})

    -- nvim-telescope/telescope-dap.nvim
    require('telescope').load_extension('dap')
    map('n', '<leader>dc', ':Telescope dap commands<CR>')
    map('n', '<leader>db', ':Telescope dap list_breakpoints<CR>')
    vim.cmd [[ autocmd FileType dap-repl lua require('dap.ext.autocompl').attach() ]]
    vim.cmd [[ autocmd BufWinEnter,BufEnter,WinEnter * if &filetype=="dap-repl" | startinsert | endif ]]

    -- theHamsta/nvim-dap-virtual-text and mfussenegger/nvim-dap
    require('nvim-dap-virtual-text').setup({
      enabled = true,                     -- enable this plugin (the default)
      enabled_commands = true,            -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
      highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
      highlight_new_as_changed = false,   -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
      show_stop_reason = true,            -- show stop reason when stopped for exceptions
      commented = true,                  -- prefix virtual text with comment string
      -- experimental features:
      virt_text_pos = 'eol',              -- position of virtual text, see `:h nvim_buf_set_extmark()`
      all_frames = false,                 -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
      virt_lines = false,                 -- show virtual lines instead of virtual text (will flicker!)
      virt_text_win_col = nil
    }
    )
    require("dapui").setup({
      mappings = {
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        edit = "<C-e>",
        repl = "r",
      },
      layouts = {
        {
          elements = {
            "breakpoints",
            "watches",
            "repl",
          },
          size = 0.25, -- 25% of total lines
          position = "bottom",
        },
      },
    })
    local dapui = require("dapui")
    -- this is similar to Emacs hook/ad-advice
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
      local wins = vim.api.nvim_list_wins()
      local target = nil
      local curr_win = vim.api.nvim_get_current_win()
      for _,win in ipairs(wins) do
        vim.api.nvim_win_call(win,function ()
          if "dap-repl"==vim.api.nvim_buf_get_option(0,"ft") then
            target = win
            vim.g.dap_repl_buffer = vim.api.nvim_win_get_buf(win)
          end
          vim.api.nvim_buf_set_keymap(0,"i","<C-w>h","<Esc><C-w>h<CR>",{noremap=true,silent=true})
          vim.api.nvim_buf_set_keymap(0,"i","<C-w>n","<Esc><C-w>j<CR>",{noremap=true,silent=true})
          vim.api.nvim_buf_set_keymap(0,"i","<C-w>e","<Esc><C-w>k<CR>",{noremap=true,silent=true})
          vim.api.nvim_buf_set_keymap(0,"i","<C-w>i","<Esc><C-w>l<CR>",{noremap=true,silent=true})
          vim.api.nvim_buf_set_keymap(0,"i","<C-LEFT>","<Esc><C-w>h<CR>",{noremap=true,silent=true})
          vim.api.nvim_buf_set_keymap(0,"i","<C-DOWN>","<Esc><C-w>j<CR>",{noremap=true,silent=true})
          vim.api.nvim_buf_set_keymap(0,"i","<C-UP>","<Esc><C-w>k<CR>",{noremap=true,silent=true})
          vim.api.nvim_buf_set_keymap(0,"i","<C-RIGHT>","<Esc><C-w>l<CR>",{noremap=true,silent=true})
        end)
      end
      if target then
        vim.api.nvim_set_current_win(target)
      else
        print("no dap-repl win opened, check nvim-dap docs")
      end
    end
    local wipe_out_repl = function()
      vim.defer_fn(function()
        pcall(function()
          vim.cmd(string.format(":bwipe! %s",vim.g.dap_repl_buffer))
        end)
      end,0)
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
      wipe_out_repl()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
      wipe_out_repl()
    end
    dap.listeners.before.disconnect["dapui_config"] = function()
      dapui.close()
      wipe_out_repl()
    end
    local breakpoints = require('dap.breakpoints')
    local breakpoints_fp = os.getenv("HOME") .. '/.cache/nvim/dap_breakpoints.json'

    local function file_exist(file_path)
      local f = io.open(file_path, "r")
      return f ~= nil and io.close(f)
    end


    if not file_exist(breakpoints_fp) then
      print(string.format("%s does not exist! now create it",breakpoints_fp))
      vim.cmd(string.format('!touch %s',breakpoints_fp))
    end

    function _G.store_breakpoints(clear)
      local bps = {}

      local load_bps_raw = io.open(breakpoints_fp, 'r'):read("*a")
      if string.len(load_bps_raw) ~= 0 and file_exist(breakpoints_fp) then -- empty string causes an error when decoding json
        bps = vim.fn.json_decode(load_bps_raw)
      end

      if clear then
        for _, bufrn in ipairs(vim.api.nvim_list_bufs()) do
          bps[vim.api.nvim_buf_get_name(bufrn)] = nil
        end
      else
        local breakpoints_by_buf = breakpoints.get()
        for _, bufrn in ipairs(vim.api.nvim_list_bufs()) do
          bps[vim.api.nvim_buf_get_name(bufrn)] = breakpoints_by_buf[bufrn]
        end
      end
      local fp = io.open(breakpoints_fp, 'w')
      if fp ~= nil then
        fp:write(vim.fn.json_encode(bps))
        fp:close()
      end
    end

    function _G.load_breakpoints()
      if not file_exist(breakpoints_fp) then
        return
      end
      local content = io.open(breakpoints_fp, 'r'):read('*a')
      if string.len(content) == 0 then
        return
      end
      local bps = vim.fn.json_decode(content)
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local file_name = vim.api.nvim_buf_get_name(buf)
        if bps[file_name] ~= nil then
          for _, bp in pairs(bps[file_name]) do
            local line = bp.line
            local opts = {
              condition = bp.condition,
              log_message = bp.logMessage,
              hit_condition = bp.hitCondition
            }
            breakpoints.set(opts, tonumber(buf), line)
          end
        end
      end
    end
  end
  return M
