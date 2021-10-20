local M = {}


-- <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/eval/typval.c#L2963-L3012>
-- <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/eval.c#L678-L711>
function M.is_truthy(value)
  local t = type(value)
  if t == 'boolean' then return value end
  if t == 'number' then return value ~= 0 end
  if t == 'string' then return value ~= '' end
  if t == 'nil' then return false end
  -- return true
  -- In accordance to the behavior of VimL:
  error(string.format('value of type %s cannot be converted to boolean', type(t)))
end


return M
