--- TODO: split this module into categories
local M = require('dotfiles.autoload')('dotfiles.utils', {
  vim = ..., ---@module 'dotfiles.utils.vim'
})

local vim_uri = require('vim.uri')
local uv = require('luv')

M.EMPTY_DICT_MT = getmetatable(vim.empty_dict())
M.NIL_MT = getmetatable(vim.NIL)

M.inspect = require('vim.inspect').inspect

-- Should the following be re-implemented? Are they part of Nvim's public API?
-- They sure are undocumented as of v0.5.0. TODO: Ask the maintainers.
do
  local vim_fn = require('vim.F')
  M.if_nil = vim_fn.if_nil
  M.ok_or_nil = vim_fn.ok_or_nil
  M.npcall = vim_fn.npcall
  M.nil_wrap = vim_fn.nil_wrap
end

local is_list = vim.islist or vim.tbl_islist
M.is_list = is_list

-- Faster and lighter alternative to `vim.validate`.
---@param name string
---@param value any
---@param expected_type type
---@param optional? boolean
---@overload fun(name: string, value: any, valid: boolean, expected?: string)
function M.check_type(name, value, expected_type, optional)
  -- Overloaded form
  if expected_type == true then      -- The check succeeded
    return
  elseif expected_type == false then -- The check failed
    local expected = optional --[[@as string]]
    error(string.format('%s: expected %s, got %s', name, expected, value))
  end
  -- Basic form
  if optional and value == nil then
    return
  end
  local actual_type = type(value)
  if actual_type ~= expected_type then
    error(string.format('%s: expected %s, got %s', name, expected_type, actual_type))
  end
end

function M.is_nil(val)
  return val == nil or val == vim.NIL
end

function M.normalize_nil(val)
  if val == vim.NIL then
    return nil
  else
    return val
  end
end

-- <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/eval/typval.c#L2963-L3012>
-- <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/eval.c#L678-L711>
-- See `:help non-zero-arg`.
function M.is_truthy(value)
  local t = type(value)
  -- stylua: ignore start
  if t == 'boolean' then return value end
  if t == 'number' then return value ~= 0 end
  if t == 'string' then return value ~= '' end
  if t == 'nil' then return false end
  if value == vim.NIL then return false end
  -- stylua: ignore end
  -- return true
  -- In accordance to the behavior of VimL:
  error(string.format('value of type %s cannot be converted to boolean', type(t)))
end

function M.clamp(x, min, max)
  return math.max(min, math.min(x, max))
end

-- Faster than `#string.format('%d', math.abs(n))` under LuaJIT, as expected.
function M.int_digit_length(n)
  return math.floor(math.log10(math.max(1, math.floor(math.abs(n))))) + 1
end

function M.list_concat(...)
  local result = {}
  local j = 1
  for arg = 1, select('#', ...) do
    local list = select(arg, ...)
    if type(list) ~= 'table' then
      error(string.format('lists[%d]: expected table, got %s', arg, type(list)))
    end
    for i = 1, #list do
      result[j] = list[i]
      j = j + 1
    end
  end
  return result
end

function M.list_index_of(list, value, pos, raw)
  if raw then
    local rawequal = rawequal
    for i = pos or 1, #list do
      if rawequal(list[i], value) then
        return i
      end
    end
  else
    for i = pos or 1, #list do
      if list[i] == value then
        return i
      end
    end
  end
end

function M.list_plug_holes_with_null(desired_len, list)
  for i = 1, desired_len do
    if list[i] == nil then
      list[i] = vim.NIL
    end
  end
  return list
end

function M.list_reverse(list)
  local len = #list
  for i = 1, len / 2 do
    list[i], list[len - i + 1] = list[len - i + 1], list[i]
  end
  return list
end

if not table.pack then
  function M.pack(...)
    return { n = select('#', ...), ... }
  end
else
  M.pack = table.pack
end

if not table.unpack then
  M.unpack = unpack
else
  M.unpack = table.unpack
end

function M.unpack_packed(list)
  return M.unpack(list, 1, list.n)
end

-- FAST FIXED-SIZE UNPACK <https://gitspartv.github.io/LuaJIT-Benchmarks/#test4> {{{
-- stylua: ignore start
function M.unpack1(t)  return t[1] end
function M.unpack2(t)  return t[1], t[2] end
function M.unpack3(t)  return t[1], t[2], t[3] end
function M.unpack4(t)  return t[1], t[2], t[3], t[4] end
function M.unpack5(t)  return t[1], t[2], t[3], t[4], t[5] end
function M.unpack6(t)  return t[1], t[2], t[3], t[4], t[5], t[6] end
function M.unpack7(t)  return t[1], t[2], t[3], t[4], t[5], t[6], t[7] end
function M.unpack8(t)  return t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8] end
function M.unpack9(t)  return t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9] end
function M.unpack10(t) return t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10] end
function M.unpack11(t) return t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11] end
function M.unpack12(t) return t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12] end
function M.unpack13(t) return t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12], t[13] end
function M.unpack14(t) return t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12], t[13], t[14] end
function M.unpack15(t) return t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12], t[13], t[14], t[15] end
function M.unpack16(t) return t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12], t[13], t[14], t[15], t[16] end
-- stylua: ignore end
-- }}}

function M.nil_pack(...)
  local tbl = {}
  for i = 1, select('#', ...) do
    local val = select(i, ...)
    if val == nil then
      val = vim.NIL
    end
    tbl[i] = val
  end
  return tbl
end

function M.tbl_to_set(tbl, default_value)
  if type(tbl) ~= 'table' then
    error(string.format('tbl: expected table, got %s', type(tbl)))
  end
  if default_value == nil then
    default_value = true
  end
  local result = {}
  for _, value in pairs(tbl) do
    result[value] = default_value
  end
  return result
end

function M.tbl_find(t, func)
  for k, v in pairs(t) do
    if func(v, k) then
      return v, k
    end
  end
end

function M.str_to_bytes(str, start, finish)
  M.check_type('str', str, 'string')
  M.check_type('start', start, 'number', true)
  M.check_type('finish', finish, 'number', true)
  local result = {}
  for i = start or 1, finish or #str do
    result[i] = string.byte(str, i)
  end
  return result
end

function M.str_from_bytes(bytes, start, finish)
  M.check_type('bytes', bytes, 'table', true)
  M.check_type('start', start, 'number', true)
  M.check_type('finish', finish, 'number', true)
  local result = {}
  for i = start or 1, finish or #bytes do
    result[i] = string.char(bytes[i])
  end
  return table.concat(result)
end

-- <https://github.com/neovim/neovim/issues/14542#issuecomment-887732686>
function M.str_to_chars(str, utf16)
  M.check_type('str', str, 'string')
  M.check_type('utf16', utf16, 'boolean', true)
  local chars = {}
  local char_idx = 1
  while true do
    local ok = true
    local char_len = 1
    if string.byte(str, 1) ~= 0 then
      ok, char_len = pcall(vim.str_byteindex, str, 1, utf16)
      if not ok then
        break
      end
    end
    chars[char_idx] = string.sub(str, 1, char_len)
    char_idx = char_idx + 1
    str = string.sub(str, char_len + 1)
  end
  return chars
end

function M.str_to_chars_iter(str, utf16)
  M.check_type('str', str, 'string')
  M.check_type('utf16', utf16, 'boolean', true)
  local char_idx = 1
  local byte_idx = 1
  return function()
    local ok = true
    local char_len = 1
    if string.byte(str, 1) ~= 0 then
      ok, char_len = pcall(vim.str_byteindex, str, 1, utf16)
      if not ok then
        return
      end
    end
    local ret_char = string.sub(str, 1, char_len)
    local ret_char_idx = char_idx
    local ret_byte_idx = byte_idx
    str = string.sub(str, char_len + 1)
    char_idx = char_idx + 1
    byte_idx = byte_idx + char_len
    return ret_char_idx, ret_byte_idx, ret_char
  end
end

function M.str_contains(str, pattern, plain)
  return string.find(str, pattern, 1, plain) ~= nil
end

function M.remove_prefix(s, prefix)
  if vim.startswith(s, prefix) then
    return s:sub(#prefix + 1)
  else
    return s
  end
end

function M.remove_suffix(s, suffix)
  if vim.endswith(s, suffix) then
    return s:sub(1, -#suffix - 1)
  else
    return s
  end
end

-- <https://github.com/dmitmel/ccloader3/blob/314624e307e0f53b48133af456e0f29d7f50090f/src/manifest.ts#L54-L72>
function M.json_path_to_string(path)
  if type(path) ~= 'table' then
    error(string.format('path: expected table, got %s', type(path)))
  end
  if vim.tbl_isempty(path) then
    return '<root>'
  end

  local result = {}

  for i, key in ipairs(path) do
    if type(key) == 'number' then
      result[i] = string.format('[%d]', key)
    elseif type(key) == 'string' then
      if key:match('^[a-zA-Z_$][a-zA-Z0-9_$]*$') then
        if i > 1 then
          result[i] = '.' .. key
        else
          result[i] = key
        end
      else
        -- TODO: Does this handle ALL escape sequences the same way JSON does?
        result[i] = string.format('[%q]', key)
      end
    else
      error(
        string.format('path[%d]: keys must be numbers or strings, instead got %s', i, type(key))
      )
    end
  end

  return table.concat(result)
end

function M.dimacall(fn, ...)
  return select(2, assert(xpcall(fn, debug.traceback, ...)))
end

-- Adapted from <https://stackoverflow.com/a/23535333/12005228>. See also:
-- <https://www.lua.org/manual/5.1/manual.html#pdf-debug.getinfo>
-- <https://www.lua.org/manual/5.1/manual.html#lua_getinfo>
-- <https://www.lua.org/manual/5.1/manual.html#lua_Debug>
-- <https://www.lua.org/pil/23.1.html>
---@param depth number?
function M.script_path(depth)
  depth = depth or 2
  local str = debug.getinfo(depth, 'S').source
  if str:sub(1, 1) == '@' then
    return str:sub(2)
  else
    return nil
  end
end

-- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/uri.lua#L77>
-- <https://github.com/neovim/neovim/commit/a2c2a086528d74bb0f6b2b68745b015f22ddd68a#diff-0ff1311ddfd42d7213ccbc416ef5783991c5fc46d1fc95a1b408f38e82aeafa1R77>
M.URI_SCHEME_PATTERN = '^([a-zA-Z][a-zA-Z0-9.+-]*):/'

-- Same as `vim_uri.uri_to_fname`, but works only on actual `file://` URLs
-- unlike the original which returns non-`file://` URLs as-is (pretending that
-- they are file paths).
function M.uri_maybe_to_fname(uri)
  if uri:match(M.URI_SCHEME_PATTERN) == 'file' then
    return vim_uri.uri_to_fname(uri)
  else
    return nil
  end
end

function M.set_timeout(delay, fn)
  M.check_type('delay', delay, 'number')
  M.check_type('fn', fn, 'function')
  local timer = uv.new_timer()
  local function stop()
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end
  timer:start(delay, 0, function()
    stop()
    return vim.schedule(fn)
  end)
  return stop
end

function M.set_interval(start_delay, repeat_delay, fn)
  M.check_type('start_delay', start_delay, 'number')
  M.check_type('repeat_delay', repeat_delay, 'number')
  M.check_type('fn', fn, 'function')
  local timer = uv.new_timer()
  local function stop()
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end
  -- The wrapping is for preventing scheduled callbacks from piling up in the
  -- queue when the interval is very short (1ms-5ms).
  timer:start(start_delay, repeat_delay, M.schedule_once_wrap(fn))
  return stop
end

--- Same as `vim.schedule_wrap()`, but if the returned function is called
--- repeatedly in a single event loop tick, the callback will be scheduled only
--- once for the next tick.
function M.schedule_once_wrap(fn)
  local is_scheduled = false
  local function scheduled_fn(...)
    is_scheduled = false
    return fn(...)
  end
  return function()
    if is_scheduled then
      return
    end
    is_scheduled = true
    return vim.schedule(scheduled_fn)
  end
end

if vim.json then
  M.json_encode = vim.json.encode
  M.json_decode = vim.json.decode
else
  M.json_encode = vim.fn.json_encode
  M.json_decode = vim.fn.json_decode
end

---@param path string
---@param opts {binary: boolean}
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
---@param opts {binary: boolean}
---@return string
function M.write_file(path, data, opts)
  opts = opts or {}
  local file = assert(io.open(path, opts.binary and 'rw' or 'w'))
  assert(file:write(data))
  assert(file:flush())
  file:close()
end

-- Shamelessly taken from <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/lsp.lua#L289-L307>.
-- This should be in the standard library.
function M.once(fn)
  local values
  return function(...)
    if not values then
      values = M.pack(fn(...))
    end
    return M.unpack(values, 1, values.n)
  end
end

return M
