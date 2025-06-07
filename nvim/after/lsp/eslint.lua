-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/eslint.lua>
-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/eslint.lua>

---@type dotfiles.lsp.Config
local config = {
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  -- <https://eslint.org/docs/user-guide/configuring/configuration-files#configuration-file-formats>
  root_markers = {
    '.eslintrc.js',
    '.eslintrc.cjs',
    '.eslintrc.yaml',
    '.eslintrc.yml',
    '.eslintrc.json',
    'package.json',
  },
}

return config
