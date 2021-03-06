local present, telescope = pcall(require, "telescope")

if not present then return end

local fixfolds = {
    hidden = true,
    attach_mappings = function(_)
        require("telescope.actions.set").select:enhance({
            post = function() vim.cmd [[normal! zx]] end
        })
        return true
    end
}

local default = {
    pickers = {
        buffers = fixfolds,
        file_browser = fixfolds,
        find_files = fixfolds,
        git_files = fixfolds,
        grep_string = fixfolds,
        live_grep = fixfolds,
        oldfiles = fixfolds,
        lsp_definitions = fixfolds,
        lsp_references = fixfolds,
        lsp_document_symbols = fixfolds,
        lsp_workspace_symbols = fixfolds,
        lsp_dynamic_workspace_symbols = fixfolds
    },
    defaults = {
        vimgrep_arguments = {
            "rg", 
            "--color=never", 
            "--no-heading", 
            "--with-filename",
            "--line-number", 
            "--column", 
            "--smart-case",
            "--no-ignore",
            "--ignore-file=" .. vim.env["HOME"] .. "/.rg_ignore"
        },
        file_ignore_patterns = {
            ".git",
            "__pycache__",
            "%.log",
            "%.npz",
            "%.npy",
            "%.pkl",
            "%.png",
            "%.jpg",
        },
        -- mappings = {
        --   i = {
        --     ["<cr>"] = function(prompt_bufnr)
        --       require('telescope.actions').select_default(prompt_bufnr)
        --       -- vim.cmd[[normal! zv]]
        --       vim.cmd[[echom "telescope hello"]]
        --     end}
        -- },
        prompt_prefix = "   ",
        selection_caret = "  ",
        entry_prefix = "  ",
        initial_mode = "insert",
        selection_strategy = "reset",
        sorting_strategy = "ascending",
        layout_strategy = "horizontal",
        layout_config = {
            horizontal = {
                prompt_position = "top",
                preview_width = 0.55,
                results_width = 0.8
            },
            vertical = {mirror = false},
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120
        },
        file_sorter = require("telescope.sorters").get_fuzzy_file,
        file_ignore_patterns = {"node_modules"},
        generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
        path_display = {"truncate"},
        winblend = 0,
        border = {},
        borderchars = {"─", "│", "─", "│", "╭", "╮", "╯", "╰"},
        color_devicons = true,
        use_less = true,
        set_env = {["COLORTERM"] = "truecolor"}, -- default = nil,
        file_previewer = require("telescope.previewers").vim_buffer_cat.new,
        grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
        qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
        -- Developer configurations: Not meant for general override
        buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker
    },
    extensions = {
        bookmarks = {
            -- Available: 'brave', 'chrome', 'edge', 'firefox', 'safari'
            selected_browser = 'chrome'
        }
    }
}

local M = {}
if override_flag then
    default = require("core.utils").tbl_override_req("telescope", default)
end

telescope.setup(default)

local extensions = {
    "themes", "terms", "bookmarks", "neoclip", "projects", "zoxide",
    "file_browser"
}
for _, ext in ipairs(extensions) do telescope.load_extension(ext) end

return M
