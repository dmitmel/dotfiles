--- ================ LSP UNIFIED SERVER SETTINGS REPOSITORY ================
---
--- The name of this subsystem abbreviates to USSR, trololo.
local M = require('dotfiles.autoload')('dotfiles.lsp.unified_settings_repository')

-- TODO: https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#setTrace

-- TODO TODO TODO
-- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1874-L1887>
-- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/handlers.lua#L160-L184>
-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workspace_didChangeConfiguration>

local lsp = require('vim.lsp')
local utils = require('dotfiles.utils')
local lsp_ignition = require('dotfiles.lsp.ignition')


-- Prior art:
-- <https://github.com/neoclide/coc.nvim/blob/c49acf35d8c32c16e1f14ab056a15308e0751688/src/configuration/util.ts#L38-L69>
-- <https://github.com/tamago324/nlsp-settings.nvim/blob/4e2523aa56d2814fd78f60fb41d7a5ccfa429207/lua/nlspsettings.lua#L31-L62>
function M.normalize(settings, vscode_style, output)
  vim.validate({
    settings = {settings, 'table'};
    vscode_style = {vscode_style, 'boolean', true};
    output = {output, 'table', true};
  })
  if vscode_style == nil then vscode_style = true end
  if output == nil then output = vim.empty_dict() end

  local current_path = {}

  -- This will create a tree structure for the leading keys (for the string
  -- `a.b.c` the leading keys are `a` and `b`) and return everything related.
  local function expand_dots_in_key(key, dest)
    local pushed_keys = 0
    local deeper_dest = dest
    local final_key = nil
    local deeper_key = nil
    for part in vim.gsplit(key, '.', true) do
      final_key = part

      if deeper_key ~= nil then
        -- Yes, I understand, the logic is a little bit wonky inside this loop,
        -- but it is to ensure that `final_key` is set to the last `part` after
        -- the loop is done, and that we get every part but the last one for
        -- `deeper_key`. The wonders of working with iterators in Lua, what can
        -- I say.

        -- Drill down the `dest` table.
        local even_deeper_dest = deeper_dest[deeper_key]
        if even_deeper_dest == nil then
          even_deeper_dest = vim.empty_dict()
          deeper_dest[deeper_key] = even_deeper_dest
        elseif type(even_deeper_dest) ~= 'table' or vim.tbl_islist(even_deeper_dest) then
          -- Whoops, sorry, can't drill into lists!
          error(
            string.format(
              "path '%s': attempted to drill a new dictionary table into the key '%s' " ..
              'while expanding dots in the settings key %q, but that key already exists ' ..
              'and has a value which does not look like a dictionary (we can only drill ' ..
              'into dictionaries!)',
              utils.json_path_to_string(current_path), deeper_key, key
            )
          )
        end
        deeper_dest = even_deeper_dest
        table.insert(current_path, deeper_key)
        pushed_keys = pushed_keys + 1
      end

      deeper_key = part
    end

    return final_key, deeper_dest, pushed_keys
  end

  -- NOTE: This function will be recursively-invoked only on dictionary-like
  -- tables. The root table is assumed to be object-like.
  local function normalize_internal(src, dest, do_dot_expansion)
    for key, value in pairs(src) do
      if type(key) ~= 'string' then
        error(
          string.format(
            "path '%s': table contains a non-string key, but only string keys may be used for " ..
            'the settings tables (as they will later be converted into JSON)',
            utils.json_path_to_string(current_path)
          )
        )
      end

      local deeper_dest = dest
      local pushed_keys = 0
      if do_dot_expansion then
        key, deeper_dest, pushed_keys = expand_dots_in_key(key, dest)
      end
      table.insert(current_path, key)
      pushed_keys = pushed_keys + 1

      if type(value) == 'table' and not vim.tbl_islist(value) then
        local value2 = {}
        if getmetatable(value) == utils.EMPTY_DICT_MT then value2 = vim.empty_dict() end
        deeper_dest[key] = value2
        -- Dot-expansion should be performed only on the first/outer layer.
        normalize_internal(value, value2, false)
      else
        -- NOTE: We can't discriminate values based on their type such as only
        -- letting in numbers/strings/booleans because some special values,
        -- such as vim.NIL, are implemented using userdata, and are very useful
        -- regardless.
        deeper_dest[key] = value
      end

      for _ = 1, pushed_keys do
        table.remove(current_path)
      end
    end
  end

  normalize_internal(settings, output, vscode_style)
  return output
end


function M.update(changed_settings)
  -- return M.update_raw(M.normalize(changed_settings))
end


function M.update_raw(changed_settings)
  -- dump(changed_settings)
end


function M.hook_on_config_installed(settings)
  settings = M.normalize(settings, true)
  -- dump(settings)
end
table.insert(lsp_ignition.service_hooks.on_config_installed, M.hook_on_config_installed)


return M
