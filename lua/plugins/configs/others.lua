local M = {}

local chadrc_config = require("core.utils").load_config()

M.autopairs = function(override_flag)
  local present1, autopairs = pcall(require, "nvim-autopairs")
  local present2, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")

  if present1 and present2 then
    local default = { fast_wrap = {} }
    if override_flag then
      default = require("core.utils").tbl_override_req("nvim_autopairs", default)
    end
    autopairs.setup(default)

    local cmp = require "cmp"
    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
  end
end

M.better_escape = function(override_flag)
  local default = {
    mapping = chadrc_config.mappings.plugins.better_escape.esc_insertmode,
    timeout = chadrc_config.plugins.options.esc_insertmode_timeout,
  }
  if override_flag then
    default = require("core.utils").tbl_override_req("better_escape", default)
  end
  require("better_escape").setup(default)
end

M.blankline = function(override_flag)
  local default = {
    indentLine_enabled = 1,
    char = "▏",
    filetype_exclude = {
      "help",
      "terminal",
      "alpha",
      "packer",
      "lspinfo",
      "TelescopePrompt",
      "TelescopeResults",
      "lsp-installer",
      "",
    },
    buftype_exclude = { "terminal" },
    show_trailing_blankline_indent = false,
    show_first_indent_level = false,
  }
  if override_flag then
    default = require("core.utils").tbl_override_req("indent_blankline", default)
  end
  require("indent_blankline").setup(default)
end

M.colorizer = function(override_flag)
  local present, colorizer = pcall(require, "colorizer")
  if present then
    local default = {
      filetypes = {
        "*",
      },
      user_default_options = {
        RGB = true, -- #RGB hex codes
        RRGGBB = true, -- #RRGGBB hex codes
        names = false, -- "Name" codes like Blue
        RRGGBBAA = false, -- #RRGGBBAA hex codes
        rgb_fn = false, -- CSS rgb() and rgba() functions
        hsl_fn = false, -- CSS hsl() and hsla() functions
        css = false, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
        css_fn = false, -- Enable all CSS *functions*: rgb_fn, hsl_fn

        -- Available modes: foreground, background
        mode = "background", -- Set the display mode.
      },
    }
    if override_flag then
      default = require("core.utils").tbl_override_req("nvim_colorizer", default)
    end
    colorizer.setup(default["filetypes"], default["user_default_options"])
    vim.cmd "ColorizerReloadAllBuffers"
  end
end

M.comment = function(override_flag)
  local present, nvim_comment = pcall(require, "Comment")
  if present then
    local default = {}
    if override_flag then
      default = require("core.utils").tbl_override_req("nvim_comment", default)
    end
    nvim_comment.setup(default)
  end
end

M.signature = function(override_flag)
  local present, lspsignature = pcall(require, "lsp_signature")
  if present then
    local default = {
      bind = true,
      doc_lines = 0,
      floating_window = true,
      fix_pos = true,
      hint_enable = true,
      hint_prefix = " ",
      hint_scheme = "String",
      hi_parameter = "Search",
      max_height = 22,
      max_width = 120, -- max_width of signature floating_window, line will be wrapped if exceed max_width
      handler_opts = {
        border = "single", -- double, single, shadow, none
      },
      zindex = 200, -- by default it will be on top of all floating windows, set to 50 send it to bottom
      padding = "", -- character to pad on left and right of signature can be ' ', or '|'  etc
    }
    if override_flag then
      default = require("core.utils").tbl_override_req("signature", default)
    end
    lspsignature.setup(default)
  end
end

M.lsp_handlers = function()
  local function lspSymbol(name, icon)
    local hl = "DiagnosticSign" .. name
    vim.fn.sign_define(hl, { text = icon, numhl = hl, texthl = hl })
  end

  lspSymbol("Error", "")
  lspSymbol("Info", "")
  lspSymbol("Hint", "")
  lspSymbol("Warn", "")

  vim.cmd([[
    autocmd ColorScheme * |
    " hi def link LspReferenceText CursorLine |
    " hi def link LspReferenceWrite CursorLine |
    " hi def link LspReferenceRead CursorLine
    " hi default LspReferenceRead cterm=bold gui=Bold ctermbg=yellow guifg=yellow guibg=purple4 |
    " hi default LspReferenceText cterm=bold gui=Bold ctermbg=red guifg=SlateBlue guibg=MidnightBlue |
    " hi default LspReferenceWrite cterm=bold gui=Bold,Italic ctermbg=red guifg=DarkSlateBlue guibg=MistyRose
    hi default LspReferenceRead guibg=#52504F
    hi default LspReferenceText guibg=#52504F
    hi default LspReferenceWrite guibg=#52504F
    ]])

  vim.diagnostic.config {
    -- virtual_text = {
    --    prefix = "",
    -- },
    virtual_text = false,
    signs = true,
    underline = false,
    update_in_insert = false,
  }

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "single",
  })
  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
    border = "single",
  })

  -- NOTE: refer to https://github.com/lucasvianav/nvim/blob/8f763b85e2da9ebd4656bf732cbdd7410cc0e4e4/lua/v/utils/lsp.lua#L98-L123
  local filter_diagnostics = function(diagnostics)
    if not diagnostics then
      return {}
    end

    -- find the "worst" diagnostic per line
    local most_severe = {}
    for _, cur in pairs(diagnostics) do
      local max = most_severe[cur.lnum]

      -- higher severity has lower value (`:h diagnostic-severity`)
      if not max or cur.severity < max.severity then
        most_severe[cur.lnum] = cur
      end
    end

    -- return list of diagnostics
    return vim.tbl_values(most_severe)
  end

  -- NOTE: refer to https://github.com/lucasvianav/nvim/blob/8f763b85e2da9ebd4656bf732cbdd7410cc0e4e4/lua/v/settings/handlers.lua#L18-L48
  ---custom namespace
  local ns = vim.api.nvim_create_namespace('severe-diagnostics')

  ---reference to the original handler
  local orig_signs_handler = vim.diagnostic.handlers.signs

  ---Overriden diagnostics signs helper to only show the single most relevant sign
  ---@see `:h diagnostic-handlers`
  vim.diagnostic.handlers.signs = {
    show = function(_, bufnr, _, opts)
      -- get all diagnostics from the whole buffer rather
      -- than just the diagnostics passed to the handler
      opts = opts or {}
      opts.severity_limit = "Error"
      local diagnostics = vim.diagnostic.get(bufnr)

      local filtered_diagnostics = filter_diagnostics(diagnostics)

      -- pass the filtered diagnostics (with the
      -- custom namespace) to the original handler
      orig_signs_handler.show(ns, bufnr, filtered_diagnostics, opts)
    end,

    hide = function(_, bufnr)
      orig_signs_handler.hide(ns, bufnr)
    end,
  }
  -- suppress error messages from lang servers
  vim.notify = function(msg, log_level)
    if msg:match "exit code" then
      return
    end
    if log_level == vim.log.levels.ERROR then
      vim.api.nvim_err_writeln(msg)
    else
      vim.api.nvim_echo({ { msg } }, true, {})
    end
  end
end

M.gitsigns = function(override_flag)
  local present, gitsigns = pcall(require, "gitsigns")
  if present then
    local default = {
      signs = {
        add = { hl = "DiffAdd", text = "│", numhl = "GitSignsAddNr" },
        change = { hl = "DiffChange", text = "│", numhl = "GitSignsChangeNr" },
        delete = { hl = "DiffDelete", text = "", numhl = "GitSignsDeleteNr" },
        topdelete = { hl = "DiffDelete", text = "‾", numhl = "GitSignsDeleteNr" },
        changedelete = { hl = "DiffChangeDelete", text = "~", numhl = "GitSignsChangeNr" },
      },
    }
    if override_flag then
      default = require("core.utils").tbl_override_req("gitsigns", default)
    end
    gitsigns.setup(default)
  end
end

return M
