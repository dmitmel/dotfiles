-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/vtsls.lua>
-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/vtsls.lua>

---@type dotfiles.lsp.Config
local config = {
  cmd = { 'vtsls', '--stdio' },
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json' },

  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}

return config
