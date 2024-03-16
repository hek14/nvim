local M = {}
function M.get_layout()
    local current_winnr = nil;
    local current_winId = vim.api.nvim_get_current_win()
    local windows = vim.api.nvim_tabpage_list_wins(0)
    local wins = {}
    for _, winId in ipairs(windows) do
        local pos = vim.api.nvim_win_get_position(winId)
        local winnr = vim.api.nvim_win_get_number(winId)
        if(current_winId == winId) then
            current_winnr = winnr
        end
        local bufnr = vim.api.nvim_win_get_buf(winId)
        local file = vim.api.nvim_buf_get_name(bufnr)
        local cursor = vim.api.nvim_win_get_cursor(winId)
        local config = vim.api.nvim_win_get_config(winId)
        config = vim.tbl_deep_extend("force", config, {winnr = winnr, x = pos[2], y = pos[1], isleaf = false, file = file, cursor = cursor})
        table.insert(wins, config)
    end
    return {
        wins = wins,
        current_winnr = current_winnr
    }
end

function M.get_split_layout()
    local windows = vim.api.nvim_tabpage_list_wins(0)
    local wins = {}
    for _, winId in ipairs(windows) do
        local pos = vim.api.nvim_win_get_position(winId)
        local winnr = vim.api.nvim_win_get_number(winId)
        local bufnr = vim.api.nvim_win_get_buf(winId)
        local file = vim.api.nvim_buf_get_name(bufnr)
        local cursor = vim.api.nvim_win_get_cursor(winId)
        local config = vim.api.nvim_win_get_config(winId)
        config = vim.tbl_deep_extend("force", config, {winnr = winnr, x = pos[2], y = pos[1], isleaf = false, file = file})
        if(config.focusable and config.relative == "") then
            table.insert(wins, config)
        end
    end
    return wins
end

return M
