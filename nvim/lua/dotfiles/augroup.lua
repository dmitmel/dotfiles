---@class dotfiles.augroup
---@field id integer
---@field name string
local augroup = require('dotfiles.autoload')('dotfiles.augroup', {})
augroup.__index = augroup

function augroup.get_global()
  ---@type dotfiles.augroup
  return setmetatable({ id = nil, name = nil }, augroup)
end

---@param name string
---@return dotfiles.augroup
function augroup.create(name, opts)
  local self = setmetatable({}, augroup)
  opts = opts or {}
  if opts.clear == nil then opts.clear = true end
  self.id = vim.api.nvim_create_augroup(name, opts)
  self.name = name
  return self
end

function augroup:delete() --
  vim.api.nvim_del_augroup_by_id(self.id)
end

---@param opts? vim.api.keyset.clear_autocmds
function augroup:clear(opts)
  opts = opts or {}
  opts.group = self.id
  vim.api.nvim_clear_autocmds(opts)
end

---@alias dotfiles.autocmd_callback string | fun(args: vim.api.keyset.create_autocmd.callback_args): boolean?

---@param event string[]|string
---@param pattern string[]|string
---@param callback dotfiles.autocmd_callback
---@param opts? vim.api.keyset.create_autocmd
---@return integer id
---@overload fun(self, event: string[]|string, callback: dotfiles.autocmd_callback, opts?: vim.api.keyset.create_autocmd): integer
function augroup:autocmd(event, pattern, callback, opts)
  if opts == nil and (callback == nil or type(callback) == 'table') then
    -- Handle the short form without a pattern.
    opts = callback or {} --[[@as vim.api.keyset.create_autocmd]]
    callback = pattern --[[@as dotfiles.autocmd_callback]]
  else
    opts = opts or {}
    opts.pattern = pattern
  end
  if type(callback) == 'function' then
    opts.callback = callback
  elseif type(callback) == 'string' then
    opts.command = callback
  end
  opts.group = self.id
  return vim.api.nvim_create_autocmd(event, opts)
end

---@param event string[]|string
---@param opts? vim.api.keyset.exec_autocmds
function augroup:exec_autocmds(event, opts)
  opts = opts or {}
  opts.group = self.id
  vim.api.nvim_exec_autocmds(event, opts)
end

---@param opts? vim.api.keyset.get_autocmds
---@return vim.api.keyset.get_autocmds.ret[]
function augroup:get_autocmds(opts)
  opts = opts or {}
  opts.group = self.id
  return vim.api.nvim_get_autocmds(opts)
end

return augroup
