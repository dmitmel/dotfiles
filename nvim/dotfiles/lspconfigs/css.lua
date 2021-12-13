-- <https://github.com/neoclide/coc-css/blob/master/src/index.ts>
-- <https://github.com/microsoft/vscode/blob/main/extensions/css-language-features/server/src/cssServer.ts>

local lsp_ignition = require('dotfiles.lsp.ignition')
local lspconfig_utils = require('lspconfig.util')
local lsp_utils = require('dotfiles.lsp.utils')

local function find_exe()
  for _, exe in ipairs({
    'vscode-css-language-server', -- <https://github.com/hrsh7th/vscode-langservers-extracted>
    'vscode-css-languageserver',  -- <https://archlinux.org/packages/community/any/vscode-css-languageserver/>
  }) do
    if vim.fn.executable(exe) ~= 0 then
      return { exe }
    end
  end
  if lsp_utils.VSCODE_INSTALL_PATH then
    local path = lsp_utils.VSCODE_INSTALL_PATH .. '/extensions/css-language-features/server/dist/node/cssServerMain.js'
    if vim.fn.filereadable(path) ~= 0 then return { 'node', path } end
  end
  return { 'vscode-css-language-server' }  -- fallback
end

lsp_ignition.setup_config('cssls', {
  cmd = vim.list_extend(find_exe(), { '--stdio' });
  filetypes = {'css', 'less', 'sass', 'scss', 'wxss'};
  -- root_dir = lspconfig_utils.root_pattern('package.json');
  single_file_support = true;
  completion_menu_label = 'CSS';

  settings_scopes = {'css', 'less', 'scss', 'wxss'};
  settings = {
    css = {
      validate = true;
      format = {
        enable = false;
      };
    };
    scss = {
      validate = true;
    };
    less = {
      validate = true;
    };
  };
})
