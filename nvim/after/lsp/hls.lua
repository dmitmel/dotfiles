-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/hls.lua>
-- <https://haskell-language-server.readthedocs.io/en/latest/configuration.html#language-specific-server-options>
-- <https://github.com/haskell/vscode-haskell/blob/master/src/extension.ts>

---@type dotfiles.lsp.Config
local config = {
  cmd = { 'haskell-language-server-wrapper', '--lsp' },
  filetypes = { 'haskell', 'lhaskell', 'cabal' },
  root_markers = { 'hie.yaml', 'stack.yaml', 'cabal.project', '*.cabal', 'package.yaml' },
}

return config
