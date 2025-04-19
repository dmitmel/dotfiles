-- Vimscript's autoloading system, but for Lua. Supports declaring namespaces
-- that can be imported automatically upon the first reference, enables
-- reloading modules by re-running them with `:source %` without breaking all
-- imported references. Inspired by:
-- <https://defold.com/manuals/modules/#hot-reloading-modules>,
-- <https://github.com/neovim/neovim/commit/2e982f1aad9f1a03562b7a451d642f76b04c37cb/#diff-1acf614023cf9d30aa08ffd8cd145cc1f8e7f704bf615cb48e1c698afc11870c>.

local MODULES = {}

---@generic T
---@param module_name string
---@param submodules? T
---@param export_to? T
---@return T
local function declare_module(module_name, submodules, export_to)
  if type(module_name) ~= 'string' then
    error(string.format('module_name: expected string, got %s', type(module_name)))
  end
  if submodules ~= nil and type(submodules) ~= 'table' then
    error(string.format('module_name: expected table, got %s', type(submodules)))
  end
  if export_to ~= nil and type(export_to) ~= 'table' then
    error(string.format('export_to: expected table, got %s', type(export_to)))
  end

  local module = rawget(MODULES, module_name)
  if module ~= nil then
    module.info.reloading = true
    module.info.reload_count = module.info.reload_count + 1
  else
    module = {
      info = {
        name = module_name,
        reloading = false,
        reload_count = 0,
      },
      exports = {},
    }

    if export_to ~= nil then
      module.exports = export_to
    end

    -- Export this table as read-only, see <https://www.lua.org/pil/13.4.5.html>
    module.exports.__module = setmetatable({}, {
      __index = function(self, k) return module.info[k] end,
      __newindex = function(self, k, v) error('attempt to update a read-only table', 2) end,
    })

    if submodules ~= nil then
      -- Lazy-load submodules
      setmetatable(module.exports, {
        __index = function(self, key)
          if submodules[key] ~= nil and type(key) == 'string' then
            local submod = require(module_name .. '.' .. key)
            rawset(self, key, submod)
            return submod
          end
        end,
      })
    end

    rawset(MODULES, module_name, module)
  end

  return module.exports
end

return declare_module
