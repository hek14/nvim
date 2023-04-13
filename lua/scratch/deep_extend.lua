local a = {x={x1=1,x2=3},y={y1={1,2,3}},7,z=99}
local b = {x={x2=4},y={2,y1={4,5,6}},5}

-- local c = vim.tbl_deep_extend('force',a,b)
-- vim.print(c)

local function deep_extend_mine_recursive(default,override)
  if type(override)~="table" or type(default)~='table' then
    return override
  end
  local result = vim.deepcopy(override)
  for k,v in pairs(default) do
    if type(k) == "number" then
      goto continue
    end
    if not override[k] then
      result[k] = v
    else
      result[k] = deep_extend_mine(v,override[k])
    end
    ::continue::
  end
  return result
end

local deep_extend_mine_non_recursive = function(default,override) 
  local result = {}
  local q = {{default,override,result}}
  while (#q>0) do
    print('running')
    local _node_default,_node_override,_node_result = unpack(q[#q])
    q[#q] = nil
    for _,k in ipairs(vim.list_extend(vim.tbl_keys(_node_default),vim.tbl_keys(_node_override))) do
      if _node_result[k] then 
        goto continue
      end
      if _node_default[k]~=nil and _node_override[k]==nil then
        if type(k)~="number" then
          _node_result[k] = _node_default[k]
        end
      end
      if not _node_default[k] and _node_override[k] then
        _node_result[k] = _node_override[k]
      end
      if _node_default[k] and _node_override[k] then
        if type(_node_default[k])~="table" or type(_node_override[k])~="table" then
          _node_result[k] = _node_override[k]
          goto continue
        end
        _node_result[k] = {}
        table.insert(q,1,{_node_default[k],_node_override[k],_node_result[k]})
      end
      ::continue::
    end
    vim.print("result now", result)
  end
  return result
end

local result = deep_extend_mine_non_recursive(a,b)
-- vim.print(result)
