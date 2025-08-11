--- Utilities and helper functions for Nvim plugin development.
local M = require('dotfiles.autoload')('dotfiles.nvim_lua_dev', {})

local utils = require('dotfiles.utils')
local Settings = require('dotfiles.lsp_settings')

M.PLUGINS_EXCLUDED_FROM_LIBRARIES = {
  ['catppuccin'] = true,
  ['fzf-lua'] = true,
  ['gitsigns.nvim'] = true,
}

--- Yep, that's right, the library list is resolved at runtime, no need for any
--- manual configuration!
---@param server 'lua_ls'|'emmylua_ls'
---@param workspace_dir string
function M.make_settings(server, workspace_dir)
  local settings = Settings.new()

  -- Basic settings for any kind of Lua project:
  if server == 'lua_ls' then
    -- <https://luals.github.io/wiki/settings/>
    settings:set('diagnostics.libraryFiles', 'Opened')
    settings:set('completion.workspaceWord', false)
    settings:set('completion.showWord', 'Disable')
    settings:set('completion.callSnippet', 'Replace')
    settings:set('completion.keywordSnippet', 'Replace')
  elseif server == 'emmylua_ls' then
    -- <https://github.com/EmmyLuaLs/emmylua-analyzer-rust/blob/main/docs/config/emmyrc_json_EN.md>
    settings:set('completion.callSnippet', true)
  end

  workspace_dir = utils.normalize_path(workspace_dir)
  local runtime_dirs = utils.map(vim.api.nvim_list_runtime_paths(), utils.normalize_path)
  local plugins_root = utils.normalize_path(vim.g['dotplug#plugins_dir']) .. '/'

  if
    not vim.tbl_contains(runtime_dirs, workspace_dir)
    and not vim.startswith(workspace_dir, plugins_root)
  then
    return settings:get()
  end

  local libraries = utils.filter(runtime_dirs, function(rtp_dir)
    if vim.fn.isdirectory(rtp_dir .. '/lua') == 0 then return false end

    rtp_dir = utils.normalize_path(rtp_dir)
    if vim.startswith(rtp_dir, plugins_root) then
      local name_end = rtp_dir:find('/', #plugins_root + 1) or 0
      local plugin_name = rtp_dir:sub(#plugins_root + 1, name_end - 1)
      if M.PLUGINS_EXCLUDED_FROM_LIBRARIES[plugin_name] then return false end
    end

    return true
  end)

  settings:set('runtime.version', jit ~= nil and 'LuaJIT' or _VERSION)

  settings:set(
    server == 'emmylua_ls' and 'runtime.requirePattern' or 'runtime.path',
    { 'lua/?.lua', 'lua/?/init.lua' }
  )

  if server == 'lua_ls' then table.insert(libraries, '${3rd}/luv/library') end
  settings:set('workspace.library', libraries)

  if server == 'lua_ls' then
    settings:set('workspace.checkThirdParty', false)
    settings:set('workspace.preloadFileSize', 1000) -- KB
    settings:set('workspace.ignoreDir', {
      '/*/',
      '!/lua/',
      '!/plugin/',
      '/lua/lspconfig/configs/',
      '/lua/conform/formatters/',
      '/lua/schemastore/catalog.lua',
      -- '/lsp/',
      -- '/tests/',
      -- '/spec/',
      -- '/ftplugin/',
      -- '/syntax/',
    })
  end

  return settings:get()
end

return M
