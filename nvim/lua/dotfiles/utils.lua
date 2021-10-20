local M = {}


--- Taken from <https://github.com/lukas-reineke/indent-blankline.nvim/blob/0a98fa8dacafe22df0c44658f9de3968dc284d20/lua/indent_blankline/utils.lua#L231-L235>.
function M.first_non_nil(...)
  for i = 1, select('#', ...) do
    local val = select(i, ...)
    if val ~= nil then
      return val
    end
  end
end


function M.tbl_to_set(tbl, default_value)
  if type(tbl) ~= 'table' then
    error(string.format('tbl: expected table, got %s', type(tbl)))
  end
  if default_value == nil then default_value = true end
  local result = {}
  for _, value in pairs(tbl) do
    result[value] = default_value
  end
  return result
end


return M
