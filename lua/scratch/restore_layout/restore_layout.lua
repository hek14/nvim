local function match(win1, win2)
    if(win1.x == win2.x and win1.width == win2.width) then
        return true
    end
    if (win1.y == win2.y and win1.height == win2.height) then
        return true
    end
    return false
end

local function swapTables(t1, t2)
    return t2, t1
end

local function merge(old_win, new_win)
    local res = nil
    if(old_win.x == new_win.x and old_win.width == new_win.width) then
        res = vim.deepcopy(old_win)
        res.height = old_win.height + new_win.height + 1 -- NOTE: 1 for the window separator
        res.split = "unknown"
        res.method = "split"
        res.meta = {old_win.height, new_win.height}
        res.childs = {vim.deepcopy(old_win), vim.deepcopy(new_win)}
        res.isleaf = false
        res.winnr = string.format("%s,%s", old_win.winnr, new_win.winnr)
    end
    if (old_win.y == new_win.y and old_win.height == new_win.height) then
        res = vim.deepcopy(old_win)
        res.width = old_win.width + new_win.width + 1
        res.split = "unknown"
        res.method = "vsplit"
        res.meta = {old_win.width, new_win.width}
        res.childs = {vim.deepcopy(old_win), vim.deepcopy(new_win)}
        res.winnr = string.format("%s,%s", old_win.winnr, new_win.winnr)
        res.isleaf = false
    end
    return res
end

local function build_layout_tree(data, stk)
    for _,win in ipairs(data) do
        -- vim.print(string.format("current: %d %s", i, vim.inspect(stk.items)))
        while(not stk:empty() and match(win, stk:top())) do
            local old_win = stk:top()
            stk:pop()
            local res = merge(old_win, win)
            if res == nil then
                -- print(string.format("fail %d %d", win.winnr, win2.winnr))
                break
            else
                -- print(string.format("success merge %d %d to %d", win.winnr, win2.winnr, res.winnr))
                win = res
            end
        end
        stk:push(win)
    end
end


local function winnr_to_winid(winnr)
    local windows = vim.api.nvim_tabpage_list_wins(0)
    for _, winid in ipairs(windows) do
        if vim.api.nvim_win_get_number(winid) == winnr then
            return winid
        end
    end
    return nil
end

local dfs_print_tree
dfs_print_tree = function(win)
    print(string.format("win: %s", win.winnr))
    if(not win.isleaf) then
        for _, c in ipairs(win.childs) do
            dfs_print_tree(c)
        end
    end
end

local bfs_layout_tree = function(root)
    vim.cmd [[ silent exe "normal! \<C-w>\<C-o>" ]]
    if(not root.childs) then
        print("only one window saved, no need to restore")
        return
    end
    local q = require("contrib.queue"):new()
    root.level = 1
    root.winid = vim.api.nvim_get_current_win()
    q:push(root)
    while(not q:empty()) do
        local t = q:front()
        q:pop()
        vim.api.nvim_set_current_win(t.winid)
        assert(t.childs and #t.childs > 0, "Error in queue!")
        local new_id = vim.api.nvim_open_win(0, false, {split = t.method == "vsplit" and "right" or "below"})
        local c1 = t.childs[1]
        c1.winid = t.winid
        c1.level = t.level + 1
        if(c1.childs) then
          q:push(c1)
        end

        local c2 = t.childs[2]
        c2.winid = new_id
        c2.level = t.level + 1
        if(c2.childs) then
          q:push(c2)
        end

        if t.method == "vsplit" then
            vim.api.nvim_win_set_config(c1.winid, {width = t.meta[1]})
        else
            vim.api.nvim_win_set_config(c1.winid, {height = t.meta[1]})
        end
    end
end

local function set_win_file(data)
    local windows = vim.api.nvim_tabpage_list_wins(0)
    assert(#windows == #data, "Length not equal")
    local final_win = nil
    for i, winId in ipairs(windows) do
        local winnr = vim.api.nvim_win_get_number(winId)
        assert (data[i].winnr == winnr, string.format("%s vs %s", data[i].winnr, winnr))
        local file = data[i].file
        if(vim.fn.filereadable(file)) then
            local bufnr = vim.fn.bufadd(file) -- TODO:if the buffer does not attach to any file, like NvimTree, need to hand these
            vim.api.nvim_win_set_buf(winId, bufnr)
            vim.api.nvim_buf_set_option(bufnr, "buflisted", true)
        else
            -- local bufnr = vim.api.nvim_create_buf(true, true)
            -- vim.api.nvim_win_set_buf(winId, bufnr)
        end

        if(winnr == data.current_winnr) then
            final_win = winId
        end
    end
    assert(final_win, "final_win is nil!")
    vim.api.nvim_set_current_win(final_win)
    vim.api.nvim_win_set_cursor(final_win, data.current_cursor)
end

local restore_layout = function(data)
    local stk = require("contrib.stack"):new()
    build_layout_tree(data, stk)
    assert(stk:size() == 1, "stk size error")
    local root = stk:top()
    stk:pop()
    bfs_layout_tree(root)
    set_win_file(data)
end

return {
    restore = restore_layout
}
