-- <https://haskell-language-server.readthedocs.io/en/latest/configuration.html#language-specific-server-options>
-- <https://github.com/haskell/vscode-haskell/blob/master/src/extension.ts>

local lsp_ignition = require('dotfiles.lsp.ignition')
local lspconfig_utils = require('lspconfig.util')

-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/hls.lua>
lsp_ignition.setup_config('hls', {
  cmd = { 'haskell-language-server-wrapper', '--lsp' },
  filetypes = { 'haskell', 'lhaskell' },
  -- root_dir = lspconfig_utils.root_pattern('*.cabal', 'stack.yaml', 'cabal.project', 'package.yaml', 'hie.yaml');
  completion_menu_label = 'Hs',

  settings_scopes = { 'haskell' },
})
