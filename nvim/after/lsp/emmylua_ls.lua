-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/emmylua_ls.lua>

-- HACK: EmmyLuaLS contains a bug wherein sending a
-- `workspace/didChangeConfiguration` notification during initialization causes
-- a deadlock, so to work around it I temporarily take the settings table out of
-- the config object to prevent them from being sent to the server here:
-- <https://github.com/neovim/neovim/blob/d7050d6e397f8916a38e8610ae8c2d8d75610fe4/runtime/lua/vim/lsp/client.lua#L562>.
-- The table in this variable is used as a unique key that will not clash with
-- anything ever, kind of like the `Symbol` type in JavaScript.
local deferred_settings_unique_key = { unique_key = 'deferred_settings' }

local function take_out(tbl, key)
  local value = tbl[key]
  tbl[key] = nil
  return value
end

---@type dotfiles.lsp.Config
local config = {
  cmd = { 'emmylua_ls' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.emmyrc.json', '.luacheckrc', '.git' },

  ---@param config vim.lsp.ClientConfig
  before_init = function(_, config)
    config[deferred_settings_unique_key] = take_out(config, 'settings')
  end,

  ---@param client vim.lsp.Client
  on_init = function(client)
    local settings = take_out(client.config, deferred_settings_unique_key)
    client.settings = vim.tbl_deep_extend('force', settings, {
      Lua = require('dotfiles.nvim_lua_dev').make_lua_ls_settings(client.root_dir),
    })
  end,
}

return config
