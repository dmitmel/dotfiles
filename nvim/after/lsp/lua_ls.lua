-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/lua_ls.lua>
-- <https://github.com/sumneko/vscode-lua/blob/master/client/src/languageserver.ts>
-- <https://github.com/sumneko/vscode-lua/blob/master/setting/schema.json>

---@type dotfiles.lsp.Config
return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = {
    '.luarc.json',
    '.luarc.jsonc',
    '.luacheckrc',
    '.stylua.toml',
    'stylua.toml',
    '.git',
  },

  settings_sections = { 'Lua' },
  on_new_config = function(config, root_dir)
    config.settings = vim.tbl_deep_extend('keep', config.settings or {}, {
      Lua = require('dotfiles.nvim_lua_dev').make_lua_ls_settings(root_dir),
    })
  end,
}
