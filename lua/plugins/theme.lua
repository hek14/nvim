local override_hl = function ()
  vim.api.nvim_set_hl(0,'Visual',{bg = '#36497d', bold = true})
  vim.api.nvim_set_hl(0,'MatchParen',{bg = '#264f78', bold = true})
  vim.cmd([[
  " hi clear CursorLine
  hi! LspReferenceWrite guibg=#264f78 gui=bold
  hi! LspReferenceRead guibg=#39424c
  hi! LspReferenceText guibg=#39424c
  hi! IndentLine guifg=#524f4f
  hi! link StatusLeft StatusLine
  hi! link StatusRight StatusLine
  hi! link StatusMid StatusLine
  hi! Gray guifg=#52504c
  ]])
end

local catppuccin = {
  "catppuccin/nvim",
  name = "catppuccin",
  event = "VeryLazy",
  config = function ()
    local ucolors = require "catppuccin.utils.colors"
    local latte = require("catppuccin.palettes").get_palette "latte"
    local frappe = require("catppuccin.palettes").get_palette "frappe"
    local macchiato = require("catppuccin.palettes").get_palette "macchiato"
    local mocha = require("catppuccin.palettes").get_palette "mocha"

    vim.g.catppuccin_flavour = "frappe"
    local colors = require("catppuccin.palettes").get_palette() -- return vim.g.catppuccin_flavour palette

    require("catppuccin").setup {
      highlight_overrides = {
        all = {
          CmpBorder = { fg = "#687fb3" },
          Visual = { style = {'bold'}, bg = "#36497d" },
          Search = { bg = "#7932a8", fg = "#1E2030" }
        },
        latte = {
          Normal = { fg = ucolors.darken(latte.base, 0.7, latte.mantle) },
        },
        frappe = {
          TSConstBuiltin = { fg = frappe.peach, style = {} },
          TSConstant = { fg = frappe.sky },
          TSComment = { fg = frappe.surface2, style = { "italic" } },
        },
        macchiato = {
          LineNr = { fg = macchiato.overlay1 }
        },
        mocha = {
          Comment = { fg = mocha.flamingo },
        },
      },
    }
    vim.cmd [[ colorscheme catppuccin ]]
  end
}

local kanagawa = {
  "rebelot/kanagawa.nvim",
  event = 'VeryLazy',
  config = function ()
    require('kanagawa').setup()
    vim.cmd [[ colorscheme kanagawa ]]
  end
}

local flipped = {
  "glepnir/flipped.nvim",
  event = "VeryLazy",
  config = function ()
    vim.cmd [[ colorscheme flipped ]]
  end
}

local newpaper = {
  "yorik1984/newpaper.nvim",
  event = "VeryLazy",
  config = function ()
    require("newpaper").setup({
      style = "light",
      lualine_style = "light"
    })
  end
}

local abscs = {
  "Abstract-IDE/Abstract-cs",
  event = "VimEnter",
  config = function ()
    vim.cmd[[colorscheme abscs]]
  end
}

local everforest = {
  "sainnhe/everforest",
  event = "VimEnter",
  config = function ()
    vim.cmd[[colorscheme everforest]]
    override_hl()
  end
}

local vscode = {
  "askfiy/visual_studio_code",
  init = function()
    vim.schedule(function ()
      require("visual_studio_code").setup({
        mode = "dark",
      })
      override_hl()
    end)
  end,
  -- priority = 100,
  config = function()
    vim.cmd([[colorscheme visual_studio_code]])
  end,
}

local material = {
  'marko-cerovac/material.nvim',
  init = function()
    vim.schedule(function ()
      vim.g.material_style = "palenight"
      vim.cmd 'colorscheme material'
      override_hl()
    end)
  end,
}

local srcery = {
  "srcery-colors/srcery-vim",
  event = "VeryLazy",
  config = function()
    vim.g.srcery_italic = 1
    vim.cmd.colorscheme('srcery')
    override_hl()
  end
}

local rose_pine = {
  'rose-pine/neovim',
  name = 'rose-pine',
  event = "VeryLazy",
  config = function()
    vim.cmd.colorscheme('rose-pine')
  end
}

local tokyonight = {
  "folke/tokyonight.nvim",
  name = "tokyonight",
  priority = 1000,
  event = "VeryLazy",
  config = function()
    local status_ok, tokyonight = pcall(require, "tokyonight")
    if not status_ok then
      return
    end
    tokyonight.setup({
      style = "storm",
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
      },
      sidebars = {
        "terminal",
        "packer",
        "help",
        "NvimTree",
        "Trouble",
        "LspInfo",
      },
      dim_inactive = false,
      lualine_bold = false,
      on_highlights = function(hl, c)
        local util = require("tokyonight.util")
        local darker_bg = util.darken(c.bg_popup, 2.5)
        hl.LineNr.fg = c.comment
        hl.CursorLineNr = {
          fg = c.fg,
          bold = true,
        }
        hl.WhichKeyGroup = {
          fg = c.green,
          bold = true,
        }
        hl.BufferVisibleMod = { fg = c.yellow, bg = c.bg }
        hl.WinSeparator = {
          fg = util.darken(c.border_highlight, 0.3),
        }
        hl.NvimTreeSpecialFile = {
          fg = c.yellow,
          bold = true,
        }
        hl.EndOfBuffer = { bg = "NONE" }
        hl.CmpDocumentation = { bg = darker_bg }
        hl.CmpDocumentationBorder = { bg = darker_bg }
        hl.TelescopeMatching = { fg = c.warning, bold = true }
        hl.TreesitterContext = { bg = c.bg_highlight }
        hl.NvimTreeFolderIcon = { fg = c.blue }
        hl.CmpBorder = { fg = c.fg_gutter, bg = "NONE" }
        hl.CmpDocBorder = { fg = c.fg_gutter, bg = "NONE" }
        hl.TelescopeBorder = { fg = c.fg_gutter, bg = "NONE" }
        hl.TelescopePromptTitle = { fg = c.blue, bg = "NONE" }
        hl.TelescopeResultsTitle = { fg = c.teal, bg = "NONE" }
        hl.TelescopePreviewTitle = { fg = c.fg, bg = "NONE" }
        hl.TelescopePromptPrefix = { fg = c.blue, bg = "NONE" }
        hl.TelescopeResultsDiffAdd = { fg = c.green, bg = "NONE" }
        hl.TelescopeResultsDiffChange = { fg = c.yellow, bg = "NONE" }
        hl.TelescopeResultsDiffDelete = { fg = c.red, bg = "NONE" }
        hl.TelescopeMatching = { fg = c.green, bold = true, bg = "NONE" }
        hl.FoldColumn = { fg = c.blue }
        hl.DevIconFish = { fg = c.green }
        hl.GHThreadSep = { bg = c.bg_float }
        hl.markdownH1 = { bg = c.bg_float }
        hl.DiagnosticUnnecessary = { fg = util.lighten(c.comment, 0.7), undercurl = true }
        hl.Directory = { fg = c.comment }
        hl.GitSignsAddNr = { fg = c.green }
        hl.GitSignsAddLn = { fg = c.green }
        hl.GitSignsAdd = { fg = c.green }
        hl.MatchParen = { bg = c.fg_gutter }
      end,
    })
    tokyonight.load()
  end,
  colors = function()
    local colors_ok, colors = pcall(require, "tokyonight.colors")
    if not colors_ok then
      return
    end
    return colors.setup({})
  end,
  util = function()
    local util_ok, util = pcall(require, "tokyonight.util")
    if not util_ok then
      return
    end

    return util
  end
}

return kanagawa
