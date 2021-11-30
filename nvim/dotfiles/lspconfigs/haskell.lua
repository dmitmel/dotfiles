-- <https://haskell-language-server.readthedocs.io/en/latest/configuration.html#language-specific-server-options>
-- <https://github.com/haskell/vscode-haskell/blob/master/src/extension.ts>

local lspconfig = require('lspconfig')

lspconfig['hls'].setup({
  completion_menu_label = 'Hs';

  settings_scopes = {'haskell'};
})
