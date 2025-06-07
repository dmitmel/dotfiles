-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/lua_ls.lua>
-- <https://github.com/sumneko/vscode-lua/blob/master/client/src/languageserver.ts>
-- <https://github.com/sumneko/vscode-lua/blob/master/setting/schema.json>

---@type dotfiles.lsp.Config
local config = {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', '.luacheckrc', '.stylua.toml', 'stylua.toml' },

  lazy_settings = function(cfg)
    return { Lua = require('dotfiles.nvim_lua_dev').make_lua_ls_settings(cfg.root_dir) }
  end,
}

return config
