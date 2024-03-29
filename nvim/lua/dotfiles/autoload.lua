-- Something similar to Vimscript's autoloading system, but for Lua, in
-- particular its aspect of being able to reload a module by re-running it.
-- Based on a tip from <https://defold.com/manuals/modules/#hot-reloading-modules>.

return setmetatable({}, {
  __call = function(self, module_name)
    -- NOTE: Path auto-detection is not used because it does not always produce
    -- the same results. When the module is `require()`d normally the
    -- `module_name` ends up being an absolute path, however, when the file is
    -- `:luafile`d or `:source`d, the path is, instead, relative to RTP,
    -- apparently.
    --[[
    if module_name == nil then
      -- <https://www.lua.org/pil/23.1.html>
      -- <https://www.lua.org/manual/5.1/manual.html#pdf-debug.getinfo>
      -- <https://www.lua.org/manual/5.1/manual.html#lua_getinfo>
      local caller_path = debug.getinfo(2, 'S').source
      if string.sub(caller_path, 1, 1) == '@' then
        module_name = string.sub(caller_path, 2)
      end
    end
    --]]

    if type(module_name) ~= 'string' then
      error(string.format('module_name: expected string, got %s', type(module_name)))
    end
    local module_internals = rawget(self, module_name)
    if module_internals == nil then
      local meta = {
        name = module_name,
        reloading = false,
        reload_count = 0,
      }
      module_internals = {
        meta = meta,
        exports = { __module = meta },
      }
      rawset(self, module_name, module_internals)
    else
      local meta = module_internals.meta
      meta.reloading = true
      meta.reload_count = meta.reload_count + 1
    end
    return module_internals.exports
  end,
})
