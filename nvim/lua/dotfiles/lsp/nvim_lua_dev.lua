--- Utilities and helper functions for Nvim plugin development.
local M = require('dotfiles.autoload')('dotfiles.lsp.nvim_lua_dev')

--- Yep, that's right, the library list is resolved at runtime, no need for
--- manual configurations!
---@param root_dir string?
function M.lua_ls_settings_for_vim(root_dir)
  ---@type { package_path: string[], libraries: table<string, boolean> }
  local settings = { package_path = {}, libraries = {} }

  --- @type string[]
  local package_config_lines = vim.split(package.config, '\n')
  -- stylua: ignore
  local pkgconf = {
    dir_sep          = package_config_lines[1], -- / or \
    path_list_sep    = package_config_lines[2], -- ;
    template_char    = package_config_lines[3], -- ?
    exe_dir_char     = package_config_lines[4], -- !
    clib_ignore_char = package_config_lines[5], -- -
  }

  -- <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/lua/vim.lua#L56-L85>
  -- <https://github.com/neovim/neovim/commit/c60c7375f5754eea2a4209cc6441e70b2bb44f14#diff-a8fd4e44d96101de6e4453a16811a686ce91e33e4767af7666481edb338d0744>
  -- <https://github.com/folke/lua-dev.nvim/blob/8c6a6e32525905a4ca0b74ca0ccd111ef0a6a49f/lua/lua-dev/sumneko.lua#L5-L52>
  for _, rtp_dir in ipairs(vim.api.nvim_list_runtime_paths()) do
    local lua_dir = rtp_dir .. pkgconf.dir_sep .. 'lua'
    if vim.fn.isdirectory(lua_dir) == 1 then
      -- TODO: Refine this check
      if not root_dir or not vim.startswith(lua_dir, root_dir) then
        -- NOTE: rtp_dir must be used here and not lua_dir!
        settings.libraries[rtp_dir] = true
      end
      -- table.insert(settings.package_path, lua_dir .. pkgconf.dir_sep .. pkgconf.template_char .. '.lua')
      -- table.insert(settings.package_path, lua_dir .. pkgconf.dir_sep .. pkgconf.template_char .. pkgconf.dir_sep .. 'init.lua')
    end
  end

  -- The Vim-specific paths are tried before Lua's `package.path` stuff, and
  -- `init.lua` must come after literal files.
  table.insert(settings.package_path, 'lua' .. pkgconf.dir_sep .. pkgconf.template_char .. '.lua')
  table.insert(
    settings.package_path,
    'lua' .. pkgconf.dir_sep .. pkgconf.template_char .. pkgconf.dir_sep .. 'init.lua'
  )
  for path in vim.gsplit(package.path, pkgconf.path_list_sep) do
    table.insert(settings.package_path, path)
  end

  return settings
end

return M
