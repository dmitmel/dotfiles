-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/emmylua_ls.lua>

---@type dotfiles.lsp.Config
local config = {
  cmd = { 'emmylua_ls' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.emmyrc.json', '.luacheckrc', '.git' },

  lazy_settings = function(cfg)
    return { Lua = require('dotfiles.nvim_lua_dev').make_lua_ls_settings(cfg.root_dir) }
  end,
}

return config
