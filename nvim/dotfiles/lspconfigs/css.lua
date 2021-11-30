-- <https://github.com/neoclide/coc-css/blob/master/src/index.ts>
-- <https://github.com/microsoft/vscode/blob/main/extensions/css-language-features/server/src/cssServer.ts>

local lspconfig = require('lspconfig')
local lsp_utils = require('dotfiles.lsp.utils')

local cmd = {'vscode-css-languageserver'}
if lsp_utils.VSCODE_INSTALL_PATH then
  cmd = {
    'node',
    lsp_utils.VSCODE_INSTALL_PATH ..
    '/extensions/css-language-features/server/dist/node/cssServerMain.js'
  }
end
vim.list_extend(cmd, {'--stdio'})

lspconfig['cssls'].setup({
  cmd = cmd;
  filetypes = {'css', 'less', 'sass', 'scss', 'wxss'};
  completion_menu_label = 'CSS';

  settings_scopes = {'css', 'less', 'scss', 'wxss'};
  settings = {
    css = {
      format = {
        enable = false;
      };
    };
  };
})
