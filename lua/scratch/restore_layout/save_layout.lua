local M = {}
function M.get_layout()
    local current_winnr = nil;
    local cursor = vim.api.nvim_win_get_cursor(0)
    local current_winId = vim.api.nvim_get_current_win()
    local windows = vim.api.nvim_tabpage_list_wins(0)
    local layoutInfo = {}
    for _, winId in ipairs(windows) do
        local pos = vim.api.nvim_win_get_position(winId)
        local winnr = vim.api.nvim_win_get_number(winId)
        if(current_winId == winId) then
            current_winnr = winnr
        end
        local bufnr = vim.api.nvim_win_get_buf(winId)
        local file = vim.api.nvim_buf_get_name(bufnr)
        local config = vim.api.nvim_win_get_config(winId)
        config = vim.tbl_deep_extend("force", config, {winnr = winnr, x = pos[2], y = pos[1], isleaf = false, file = file})
        if(config.focusable and config.relative == "") then -- NOTE:ignore the floating windows and buffers that don't attach to files
          table.insert(layoutInfo, config)
        end
    end
    layoutInfo.current_winnr =  current_winnr
    layoutInfo.current_cursor = cursor
    return layoutInfo
end
return M
