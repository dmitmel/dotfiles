--- Utilities and helper functions for Nvim plugin development.
local M = require('dotfiles.autoload')('dotfiles.nvim_lua_dev', {})

local utils = require('dotfiles.utils')

-- <https://luals.github.io/wiki/settings/>
M.DEFAULT_LUA_LS_SETTINGS = {
  runtime = {
    version = 'LuaJIT',
  },
  workspace = {
    preloadFileSize = 1000, -- KB
    -- library = { vim.env.VIMRUNTIME },
    ignoreDir = {
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
    },
  },
  diagnostics = {
    globals = { 'vim' },
    disable = { 'empty-block' },
    libraryFiles = 'Opened',
  },
  completion = {
    workspaceWord = false,
    showWord = 'Disable',
    callSnippet = 'Replace',
    keywordSnippet = 'Replace',
  },
  format = {
    enabled = false,
  },
}

M.PLUGINS_EXCLUDED_FROM_LIBRARIES = {
  ['catppuccin'] = true,
  ['fzf-lua'] = true,
  ['gitsigns.nvim'] = true,
}

--- Yep, that's right, the library list is resolved at runtime, no need for
--- manual configurations!
---@param root_dir string?
function M.make_lua_ls_settings(root_dir)
  root_dir = root_dir or vim.g.dotfiles_dir --[[@as string]]

  local libraries = { '${3rd}/luv/library' } ---@type string[]

  --- @type string[]
  local pkgconf = vim.split(package.config, '\n')
  local sep = pkgconf[1] -- / or \

  local plugins_root = vim.g['dotplug#plugins_dir'] .. sep
  for _, rtp_dir in ipairs(vim.api.nvim_list_runtime_paths()) do
    if vim.startswith(rtp_dir, plugins_root) then
      local plugin_dir = string.sub(rtp_dir, #plugins_root + 1)
      if M.PLUGINS_EXCLUDED_FROM_LIBRARIES[plugin_dir] then goto continue end
    end
    local lua_dir = rtp_dir .. sep .. 'lua'
    if vim.fn.isdirectory(lua_dir) == 1 and not vim.startswith(lua_dir, root_dir) then
      table.insert(libraries, rtp_dir)
    end
    ::continue::
  end

  local path_list_sep = pkgconf[2] -- ;
  local template_char = pkgconf[3] -- ?
  local package_path = vim.split(package.path, path_list_sep)

  local _, i = utils.find(package_path, '.' .. sep .. template_char .. '.lua')
  -- `init.lua` must come after normal modules in `package.path`.
  table.insert(package_path, i + 1, '.' .. sep .. template_char .. sep .. 'init.lua')
  table.insert(package_path, i + 2, 'lua' .. sep .. template_char .. '.lua')
  table.insert(package_path, i + 3, 'lua' .. sep .. template_char .. sep .. 'init.lua')

  package_path = {
    'lua' .. sep .. template_char .. '.lua',
    'lua' .. sep .. template_char .. sep .. 'init.lua',
  }

  return vim.tbl_deep_extend('keep', M.DEFAULT_LUA_LS_SETTINGS, {
    runtime = { path = package_path },
    workspace = { library = libraries },
  })
end

return M
