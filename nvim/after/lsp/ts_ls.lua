-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/ts_ls.lua>
-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/ts_ls.lua>
-- <https://github.com/typescript-language-server/typescript-language-server/blob/master/docs/configuration.md>

---@type dotfiles.lsp.Config
local config = {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json' },
}

return config
