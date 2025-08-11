---@class dotfiles.lsp.Settings
--- A class for processing and editing LSP settings objects. I used this code
--- from neoconf.nvim as a basis for my implementation:
--- <https://github.com/folke/neoconf.nvim/blob/main/lua/neoconf/settings.lua>.
--- The methods in this class will not mutate any tables provided as arguments,
--- making copies instead, and reusing those copies whenever possible. The
--- tables returned by its methods can also be treated as immutable.
---@field private _json lsp.LSPAny
---@field private _owned table<table, true>
local Settings = require('dotfiles.autoload')('dotfiles.lsp_settings', {})
Settings.__index = Settings

local utils = require('dotfiles.utils')

local function can_merge(v)
  return type(v) == 'table' and (utils.is_empty(v) or not utils.is_list(v))
end

---@param json? lsp.LSPAny
function Settings.new(json)
  local self = setmetatable({}, Settings)
  self._json = json
  self._owned = nil
  self:_disown_all()
  return self
end

--- Expand a VSCode-style settings object with dotted keys into a hierarchical table.
---@param tbl lsp.LSPObject
function Settings.expand(tbl)
  if type(tbl) ~= 'table' then return tbl end
  local ret = Settings.new()
  for key, value in pairs(tbl) do
    assert(type(key) == 'string')
    ret:set(key, value)
  end
  return ret
end

--- A lazy solution to the problem of ownership of returned tables: any accessor
--- method must relinquish ownership of EVERY intermediate table, so that the
--- returned tables will not be mutated in any way.
---@private
function Settings:_disown_all() self._owned = setmetatable({}, { __mode = 'kv' }) end

---@private
---@param tbl table
---@return table
function Settings:_ensure_owned(tbl)
  if self._owned[tbl] then return tbl end
  local copied = setmetatable({}, getmetatable(tbl))
  for k, v in pairs(tbl) do
    copied[k] = v
  end
  self._owned[copied] = true
  return copied
end

---@private
function Settings:_mark_owned(tbl)
  self._owned[tbl] = true
  return tbl
end

---@param path string|any[]|nil
---@return string[]
local function split_path(path)
  if path == nil or path == '' then
    return {}
  elseif type(path) == 'table' then
    return path
  else
    return vim.split(path, '.', { plain = true })
  end
end

---@private
---@param path string|any[]|nil
---@return table tbl
---@return any last_key
function Settings:_create_path(path)
  ---@type table, any
  local tbl, key = self, '_json'
  for _, next_key in ipairs(split_path(path)) do
    local next_tbl = tbl[key]
    if type(next_tbl) ~= 'table' then
      next_tbl = self:_mark_owned({})
    else
      next_tbl = self:_ensure_owned(next_tbl)
    end
    tbl[key] = next_tbl
    tbl, key = next_tbl, next_key
  end
  return tbl, key
end

---@param path string|any[]|nil
---@param value lsp.LSPAny|nil
function Settings:set(path, value)
  local tbl, last_key = self:_create_path(path)
  tbl[last_key] = value
end

---@param path string|any[]|nil
---@param value lsp.LSPAny
function Settings:set_default(path, value)
  local tbl, last_key = self:_create_path(path)
  if tbl[last_key] == nil then tbl[last_key] = value end
end

---@param path string|any[]|nil
---@param updater fun(prev?: any): any
function Settings:update(path, updater)
  local tbl, last_key = self:_create_path(path)
  tbl[last_key] = updater(tbl[last_key])
end

---@param path string|any[]|nil
---@param default? lsp.LSPAny
---@return lsp.LSPAny|nil
function Settings:get(path, default)
  self:_disown_all()
  local value = self._json
  for _, key in ipairs(split_path(path)) do
    if type(value) ~= 'table' then return default end
    value = value[key]
  end
  if value == nil then return default end
  return value
end

---@param keys string[]
---@return lsp.LSPObject
function Settings:pick(keys)
  self:_disown_all()
  local result = {}
  if type(self._json) == 'table' then
    for _, key in ipairs(keys) do
      result[key] = self._json[key]
    end
  end
  return result
end

---@alias dotfiles.lsp.SettingsMergeRule
---| table<any, dotfiles.lsp.SettingsMergeRule>
---| (fun(prev: any, value: any): any)

---@param other lsp.LSPAny
---@param merge_rule? dotfiles.lsp.SettingsMergeRule
function Settings:merge(other, merge_rule)
  self._json = self:_merge_recurse(true, self._json, other, merge_rule)
end

---@param other lsp.LSPAny
---@param merge_rule? dotfiles.lsp.SettingsMergeRule
function Settings:merge_defaults(other, merge_rule)
  self._json = self:_merge_recurse(false, self._json, other, merge_rule)
end

---@private
---@param force boolean
---@param dest lsp.LSPAny
---@param src lsp.LSPAny
---@param merge_rule? dotfiles.lsp.SettingsMergeRule
function Settings:_merge_recurse(force, dest, src, merge_rule)
  if type(merge_rule) == 'function' then
    dest = merge_rule(dest, src)
  elseif can_merge(dest) and can_merge(src) then
    ---@cast dest lsp.LSPObject
    ---@cast src lsp.LSPObject
    dest = self:_ensure_owned(dest)
    for k, v in pairs(src) do
      dest[k] = self:_merge_recurse(force, dest[k], v, merge_rule and merge_rule[k])
    end
    -- TODO: handle empty_dicts better
    -- if utils.is_empty(left) then left = self:_mark_owned(vim.empty_dict()) end
  elseif src ~= nil and (force or dest == nil) then
    dest = src
  end
  return dest
end

---@alias dotfiles.lsp.SettingsProvider
---| table<any, dotfiles.lsp.SettingsProvider>
---| (fun(): any)

---@param provider dotfiles.lsp.SettingsProvider
function Settings:provide(provider) self._json = self:_provide_recurse(provider, self._json) end

---@private
---@param provider dotfiles.lsp.SettingsProvider
---@param dest lsp.LSPAny
function Settings:_provide_recurse(provider, dest)
  if type(provider) == 'function' and dest == nil then
    return provider()
  elseif type(provider) == 'table' then
    if not can_merge(dest) then
      dest = {}
      self._owned[dest] = true
    end
    ---@cast dest lsp.LSPObject
    dest = self:_ensure_owned(dest)
    for k, v in pairs(provider) do
      dest[k] = self:_provide_recurse(v, dest[k])
    end
  end
  return dest
end

return Settings
