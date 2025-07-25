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
---@return boolean
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

---@param x table
function M.is_empty(x) return next(x) == nil end

--- Replacement for |vim.tbl_map()| for which type inference actually works.
---@generic T, U
---@param list T[]
---@param func fun(value: T): U
---@return U[]
---@see vim.tbl_map
function M.map(list, func)
  local result = {}
  for i, v in ipairs(list) do
    result[i] = func(v)
  end
  return result
end

--- Replacement for |vim.tbl_filter()| for which type inference actually works.
---@generic T
---@param list T[]
---@param func fun(value: T): boolean
---@return T[]
---@see vim.tbl_filter
function M.filter(list, func)
  local result = {}
  for _, v in ipairs(list) do
    if func(v) then result[#result + 1] = v end
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
---@return T[] removed
function M.remove_all(list, predicate)
  local i = 1
  local removed = {}
  while list[i] ~= nil do -- Bruh, fuckin' C
    if predicate(list[i]) then
      local item = table.remove(list, i)
      table.insert(removed, item)
    else
      i = i + 1
    end
  end
  return removed
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
  for _, value in ipairs(list) do
    set[value] = true
  end
  return set
end

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
  local data = assert(file:read('*a'))
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

function M.is_inside_dir(path, dir)
  path = vim.fs.normalize(path, { expand_env = false })
  dir = vim.fs.normalize(dir, { expand_env = false })
  return vim.startswith(path, dir) and path:sub(#dir + 1, #dir + 1) == '/'
end

---@param bufnr integer
---@return integer
function M.get_inmemory_buf_size(bufnr)
  return vim.api.nvim_buf_get_offset(bufnr, vim.api.nvim_buf_line_count(bufnr))
end

---@param bufnr integer|nil
---@return integer
function M.resolve_bufnr(bufnr)
  if bufnr == 0 or bufnr == nil then
    return vim.api.nvim_get_current_buf()
  elseif vim.api.nvim_buf_is_valid(bufnr) then
    return bufnr
  else
    error('bufnr is not valid: ' .. bufnr)
  end
end

---@param name string
---@param opts? vim.api.keyset.create_augroup
---@return dotfiles.augroup
function M.augroup(name, opts) return require('dotfiles.augroup').create(name, opts) end

function M.pack(...) return { n = select('#', ...), ... } end

---@generic F: function
---@param callback F
---@return F
function M.schedule_once_per_tick(callback)
  local scheduled = false
  return function(...)
    if not scheduled then
      scheduled = true
      local args = M.pack(...)
      vim.schedule(function()
        scheduled = false
        callback(unpack(args, 1, args.n))
      end)
    end
  end
end

---@generic F: function
---@param callback F
---@return F
function M.once(callback)
  local results
  return function(...)
    results = results or M.pack(callback(...))
    return unpack(results, 1, results.n)
  end
end

---@param co thread
local function async_step(co, ...)
  local ok, err = coroutine.resume(co, ...)
  if not ok then error(debug.traceback(co, err)) end
end

---@param fn async fun(...)
function M.run_async(fn, ...)
  local co = coroutine.create(fn)
  async_step(co, ...)
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
    assert(not results, 'callback must be called only once')
    results = M.pack(...)
    if coroutine.status(co) == 'suspended' then async_step(co) end
  end

  fn(async_callback)

  if not results then coroutine.yield() end
  assert(results, 'callback did not get called')
  return unpack(results, 1, results.n)
end

function M.event()
  ---@class dotfiles.Event
  local self = {}

  --- This is private
  local listeners = {}
  --- The number of attached listeners. This is exposed for debugging purposes.
  self.listeners = 0

  ---@param listener fun(...): boolean?
  ---@param once boolean
  ---@return function
  function self:subscribe(listener, once)
    -- The listener is wrapped in a table to ensure we can tell apart listeners
    -- which are actually the same function added multiple times.
    local unique_ref = { listener = listener, once = once }
    table.insert(listeners, unique_ref)
    self.listeners = self.listeners + 1

    local function unsubscribe()
      for i, other_ref in ipairs(listeners) do
        if other_ref == unique_ref then
          table.remove(listeners, i)
          self.listeners = self.listeners - 1
          return
        end
      end
      error('this listener was already removed')
    end

    return unsubscribe
  end

  --- Just a convenience wrapper around `subscribe()` to make the code clearer.
  ---@param listener fun(...)
  ---@return function
  function self:subscribe_once(listener) return self:subscribe(listener, true) end

  function self:__call(...)
    local i = 1
    while listeners[i] ~= nil do
      local unsub = listeners[i].listener(...)
      if unsub or listeners[i].once then
        table.remove(listeners, i)
        self.listeners = self.listeners - 1
      else
        i = i + 1
      end
    end
  end

  return setmetatable(self, self)
end

function M.gcfun(fn)
  -- setmetatable() can't be called on a userdata object, so we do it in a
  -- roundabout way: create a blank userdata with an empty metatable already
  -- attached, that we will modify.
  local proxy = newproxy(true)
  getmetatable(proxy).__gc = fn
  return proxy
end

--- Generates a `complete` function suitable for `nvim_create_user_command()`,
--- which handles the matching and sorting of the results given by `get_strings`.
---@param get_strings fun(): string[]
---@return fun(arg_lead: string, cmd_line: string, cursor_pos: integer): string[] completion_fn
function M.command_completion_fn(get_strings)
  return function(arg_lead)
    local results = {} ---@type string[]
    -- The lower the score, the better.
    local scores = {} ---@type table<string, integer>

    local fuzzy = vim.tbl_contains(vim.opt.wildoptions:get(), 'fuzzy')

    local function filter(str)
      if fuzzy then
        return string.find(str, arg_lead, 1, true) or 0
      else
        return vim.startswith(str, arg_lead) and 1 or 0
      end
    end

    for _, str in ipairs(get_strings()) do
      local score = filter(str)
      if score > 0 and not scores[str] then
        results[#results + 1] = str
        scores[str] = score
      end
    end

    table.sort(results, function(a, b)
      if scores[a] == scores[b] then
        return vim.stricmp(a, b) < 0
      else
        return scores[a] < scores[b]
      end
    end)
    return results
  end
end

return M
