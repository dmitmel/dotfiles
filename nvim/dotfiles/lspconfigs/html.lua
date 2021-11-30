-- <https://github.com/neoclide/coc-html/blob/master/src/index.ts>
-- <https://github.com/microsoft/vscode/blob/main/extensions/html-language-features/server/src/htmlServer.ts>

local lspconfig = require('lspconfig')
local lsp_utils = require('dotfiles.lsp.utils')

local cmd = {'vscode-html-languageserver'}
if lsp_utils.VSCODE_INSTALL_PATH then
  cmd = {
    'node',
    lsp_utils.VSCODE_INSTALL_PATH ..
    '/extensions/html-language-features/server/dist/node/htmlServerMain.js'
  }
end
vim.list_extend(cmd, {'--stdio'})

lspconfig['html'].setup({
  cmd = cmd;
  filetypes = {'html', 'handlebars', 'htmldjango', 'blade'};
  completion_menu_label = 'HTML';

  settings_scopes = {'html', 'css', 'javascript'};
  settings = {
    html = {
      format = {
        enable = false;
      };
    };
    javascript = {
      format = {
        enable = false;
      };
    };
    css = {
      format = {
        enable = false;
      };
    };
  };
})
