-- Vimscript's autoloading system, but for Lua. Supports declaring namespaces
-- that can be imported automatically upon the first reference, enables
-- reloading modules by re-running them with `:source %` without breaking all
-- imported references. Inspired by:
-- <https://defold.com/manuals/modules/#hot-reloading-modules>,
-- <https://github.com/neovim/neovim/commit/2e982f1aad9f1a03562b7a451d642f76b04c37cb/#diff-1acf614023cf9d30aa08ffd8cd145cc1f8e7f704bf615cb48e1c698afc11870c>.

---@class dotfiles.autoload.Module
---@field name string
---@field exports any
---@field reload_count integer

local MODULES = {} ---@type table<string, dotfiles.autoload.Module>

---@generic T
---@param name string
---@param exports T
---@param submodules? T
---@return T exports
---@return dotfiles.autoload.Module module
local function declare_module(name, exports, submodules)
  if type(name) ~= 'string' then
    error(string.format('name: expected string, got %s', type(name)))
  end
  if exports ~= nil and type(exports) ~= 'table' then
    error(string.format('exports: expected table, got %s', type(exports)))
  end
  if submodules ~= nil and type(submodules) ~= 'table' then
    error(string.format('module_name: expected table, got %s', type(submodules)))
  end

  local module = rawget(MODULES, name) ---@type dotfiles.autoload.Module|nil
  if module == nil then
    module = {
      name = name,
      reload_count = 0,
      exports = exports or {},
    }
    rawset(MODULES, name, module)
  else
    module.reload_count = module.reload_count + 1
  end

  if submodules ~= nil and next(submodules) ~= nil then
    local mt = getmetatable(module.exports) or {}

    function mt.__index(self, key)
      if submodules[key] ~= nil then
        local submod = require(name .. '.' .. key)
        rawset(self, key, submod)
        return submod
      end
    end

    setmetatable(module.exports, mt)
  end

  return module.exports, module
end

return declare_module
