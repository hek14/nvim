return {
  "folke/edgy.nvim",
  enabled = false,
  event = "VeryLazy",
  init = function()
    vim.opt.laststatus = 3
    vim.opt.splitkeep = "screen"
  end,
  opts = {
    keys = {
      -- close window
      ["q"] = function(win)
        win:close()
      end,
      -- hide window
      ["<c-q>"] = function(win)
        win:hide()
      end,
      -- close sidebar
      ["Q"] = function(win)
        win.view.edgebar:close()
      end,
      -- next open window
      ["]w"] = function(win)
        win:next({ visible = true, focus = true })
      end,
      -- previous open window
      ["[w"] = function(win)
        win:prev({ visible = true, focus = true })
      end,
      -- next loaded window
      ["]W"] = function(win)
        win:next({ pinned = false, focus = true })
      end,
      -- prev loaded window
      ["[W"] = function(win)
        win:prev({ pinned = false, focus = true })
      end,
      -- increase width
      ["<c-w>>"] = function(win)
        win:resize("width", 2)
      end,
      -- decrease width
      ["<c-w><lt>"] = function(win)
        win:resize("width", -2)
      end,
      -- increase height
      ["<c-w>+"] = function(win)
        win:resize("height", 2)
      end,
      -- decrease height
      ["<c-w>-"] = function(win)
        win:resize("height", -2)
      end,
      -- reset all custom sizing
      ["<c-w>="] = function(win)
        win.view.edgebar:equalize()
      end,
    },
    bottom = {
      -- toggleterm / lazyterm at the bottom with a height of 40% of the screen
      {
        ft = "toggleterm",
        size = { height = 0.4 },
        -- exclude floating windows
        filter = function(buf, win)
          return vim.api.nvim_win_get_config(win).relative == ""
        end,
      },
      {
        ft = "lazyterm",
        title = "LazyTerm",
        size = { height = 0.4 },
        filter = function(buf)
          return not vim.b[buf].lazyterm_cmd
        end,
      },
      "Trouble",
      { ft = "qf", title = "QuickFix" },
      {
        ft = "help",
        size = { height = 20 },
        -- only show help buffers
        filter = function(buf)
          return vim.bo[buf].buftype == "help"
        end,
      },
      { ft = "spectre_panel", size = { height = 0.4 } },
    },
    left = {
      -- Neo-tree filesystem always takes half the screen height
      {
        title = "Neo-Tree",
        ft = "neo-tree",
        filter = function(buf)
          print("current filetring")
          return vim.b[buf].neo_tree_source == "filesystem"
        end,
        size = { height = 0.5 },
      },
      {
        title = "NvimTree",
        ft = "NvimTree",
        filter = function(buf)
          print("current filetring", buf)
          return true
        end,
        size = { width = 0.5 },
      },
      {
        title = "Neo-Tree Git",
        ft = "neo-tree",
        filter = function(buf)
          return vim.b[buf].neo_tree_source == "git_status"
        end,
        pinned = true,
        open = "Neotree position=right git_status",
      },
      {
        title = "Neo-Tree Buffers",
        ft = "neo-tree",
        filter = function(buf)
          return vim.b[buf].neo_tree_source == "buffers"
        end,
        pinned = true,
        open = "Neotree position=top buffers",
      },
      {
        ft = "Outline",
        pinned = true,
        open = "SymbolsOutlineOpen",
      },
      -- any other neo-tree windows
      "neo-tree",
    },
  },
}
