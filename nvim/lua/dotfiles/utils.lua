-- TODO: Make a PR to neovim for vim.regex improvements:
-- match() matchend() matchlist() matchstr() matchstrpos() split() substitute()

local M = require('dotfiles.autoload')('dotfiles.utils', _G.dotutils)
_G.dotutils = M

-- <https://www.compart.com/en/unicode/block/U+2500>
-- <https://www.compart.com/en/unicode/block/U+2580>
-- <https://www.compart.com/en/unicode/block/U+1FB00>
M.border_styles = {
  left = { '', '', '', '', '', '', '', '│' },
  right = { '', '', '', '│', '', '', '', '' },
  top = { '', '─', '', '', '', '', '', '' },
  bottom = { '', '', '', '', '', '─', '', '' },

  hpad = { '', '', '', ' ', '', '', '', ' ' },
  vpad = { '', ' ', '', '', '', ' ', '', '' },

  outset = { '🭽', '▔', '🭾', '▕', '🭿', '▁', '🭼', '▏' },

  inset = { ' ', '▁', ' ', '▎', ' ', '▔', ' ', '🮇' },
}

function M.has(feature) return vim.fn.has(feature) ~= 0 end
function M.exists(feature) return vim.fn.exists(feature) ~= 0 end

-- Faster and lighter alternative to `vim.validate`.
---@param name string
---@param value any
---@param expected_type type
---@param optional? boolean
---@overload fun(name: string, value: any, valid: boolean, expected?: string)
function M.check_type(name, value, expected_type, optional)
  -- Overloaded form
  if expected_type == true then -- The check succeeded
    return
  elseif expected_type == false then -- The check failed
    local expected = optional --[[@as string]]
    error(string.format('%s: expected %s, got %s', name, expected, value))
  end
  -- Basic form
  if optional and value == nil then return end
  local actual_type = type(value)
  if actual_type ~= expected_type then
    error(string.format('%s: expected %s, got %s', name, expected_type, actual_type))
  end
end

-- <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/eval/typval.c#L2963-L3012>
-- <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/eval.c#L678-L711>
-- See `:help non-zero-arg`.
function M.is_truthy(value)
  local t = type(value)
  if t == 'boolean' then return value end
  if t == 'number' then return value ~= 0 end
  if t == 'string' then return value ~= '' end
  if t == 'nil' then return false end
  if value == vim.NIL then return false end
  -- In accordance to the behavior of Vimscript:
  error(string.format('value of type %s cannot be converted to boolean', type(t)))
end

function M.clamp(x, min, max) return math.max(min, math.min(x, max)) end
function M.round(x) return math.floor(x + 0.5) end

M.is_list = vim.islist or vim.tbl_islist ---@diagnostic disable-line: deprecated

--- Straight-up stolen from <https://github.com/neovim/neovim/blob/v0.11.0/runtime/lua/vim/shared.lua#L1412-L1420>.
--- This function was added only in v0.11.0, but is useful nonetheless.
--- @generic T
--- @param x elem_or_list<T>?
--- @return T[]
function M.ensure_list(x)
  if type(x) == 'table' then
    return x
  else
    return { x }
  end
end

--- Replacement for |vim.tbl_map()| for which type inference actually works.
---@generic T, U
---@param list T[]
---@param func fun(x: T): U
---@return U[]
---@see vim.tbl_map
function M.map(list, func)
  local result = {}
  for i, v in ipairs(list) do
    result[i] = func(v)
  end
  return result
end

---@generic T
---@param list T[]
---@param predicate T | fun(x: T): boolean
---@return T? value
---@return integer? index
function M.find(list, predicate)
  if not vim.is_callable(predicate) then
    local y = predicate
    predicate = function(x) return x == y end
  end
  for index, value in ipairs(list) do
    if predicate(value) then return value, index end
  end
end

---@generic T
---@param list T[]
---@param predicate fun(item: T): boolean
function M.remove_all(list, predicate)
  local i = 1
  while list[i] ~= nil do -- Bruh, fuckin' C
    if predicate(list[i]) then
      table.remove(list, i)
    else
      i = i + 1
    end
  end
end

---@generic T
---@param value T|nil
---@param default T
---@return T
function M.if_nil(value, default)
  if value ~= nil then
    return value
  else
    return default
  end
end

---@param tbl table
function M.clear_table(tbl)
  for key in pairs(tbl) do
    tbl[key] = nil
  end
end

---@generic T
---@param list T[]
---@return table<T, boolean>
function M.list_to_set(list)
  local set = {}
  for _, value in pairs(list) do
    set[value] = true
  end
  return set
end

---@generic T
---@param ... T
---@return T
function M.inplace_merge(...) return require('snacks').config.merge(...) end

-- Adapted from <https://stackoverflow.com/a/23535333/12005228>. See also:
-- <https://www.lua.org/manual/5.1/manual.html#pdf-debug.getinfo>
-- <https://www.lua.org/manual/5.1/manual.html#lua_getinfo>
-- <https://www.lua.org/manual/5.1/manual.html#lua_Debug>
-- <https://www.lua.org/pil/23.1.html>
function M.script_relative(path)
  local info = debug.getinfo(2, 'S')
  assert(info.source:sub(1, 1) == '@', 'could not determine path to the current script')
  local script_file = info.source:sub(2)
  local script_dir = vim.fn.fnamemodify(script_file, ':h')
  return vim.fn.simplify(script_dir .. '/' .. path)
end

---@param path string
---@param opts? {binary: boolean}
---@return string
function M.read_file(path, opts)
  opts = opts or {}
  local file = assert(io.open(path, opts.binary and 'rb' or 'r'))
  local data = file:read('*a')
  file:close()
  return data
end

---@param path string
---@param data string
---@param opts? {binary: boolean}
function M.write_file(path, data, opts)
  opts = opts or {}
  local file = assert(io.open(path, opts.binary and 'wb' or 'w'))
  assert(file:write(data))
  assert(file:flush())
  file:close()
end

---@param bufnr integer
---@return integer
function M.get_inmemory_buf_size(bufnr)
  return vim.api.nvim_buf_get_offset(bufnr, vim.api.nvim_buf_line_count(bufnr))
end

---@param chunks string|[string,string?][]
---@param hl_group? string
function M.echo(chunks, hl_group)
  if type(chunks) == 'string' then chunks = { { chunks, hl_group } } end
  vim.api.nvim_echo(chunks, false, {})
end

---@param chunks string|[string,string?][]
---@param hl_group? string
function M.echomsg(chunks, hl_group)
  if type(chunks) == 'string' then chunks = { { chunks, hl_group } } end
  vim.api.nvim_echo(chunks, true, {})
end

---@param name string
---@param opts? vim.api.keyset.create_augroup
---@return dotfiles.augroup
function M.augroup(name, opts) return require('dotfiles.augroup').create(name, opts) end

---@generic F: function
---@param callback F
---@return F
function M.schedule_once_per_frame(callback)
  local scheduled = false
  return function(...)
    if not scheduled then
      scheduled = true
      local args = { ... }
      local args_len = select('#', ...)
      vim.schedule(function()
        scheduled = false
        callback(unpack(args, 1, args_len))
      end)
    end
  end
end

---@generic F: function
---@param callback F
---@return F
function M.once(callback)
  local called = false
  return function(...)
    if not called then
      called = true
      return callback(...)
    end
  end
end

--- Helper for turning callback-based APIs into asynchronous functions. Based on
--- <https://github.com/gregorias/coerce.nvim/blob/4ea7e31b95209105899ee6360c2a3a30e09d361d/lua/coerce/coroutine.lua>
--- and <https://gregorias.github.io/posts/using-coroutines-in-neovim-lua/>.
---@param fn fun(callback: fun(...))
---@return ...
function M.await(fn)
  local co = assert(coroutine.running(), 'needs to be called within a coroutine')
  local results = nil

  local function async_callback(...)
    results = { n = select('#', ...), ... }
    if coroutine.status(co) == 'suspended' then
      local ok, err = coroutine.resume(co)
      if not ok then error(debug.traceback(co, err)) end
    end
  end

  fn(async_callback)

  if not results then coroutine.yield() end
  assert(results, 'async callback did not get called')
  return unpack(results, 1, results.n)
end

return M
