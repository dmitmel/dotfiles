-- <https://github.com/MaskRay/vscode-ccls/blob/master/src/serverContext.ts>

local lspconfig = require('lspconfig')

local cache_dir = vim.call('dotfiles#paths#xdg_cache_home') .. '/ccls'
lspconfig['ccls'].setup({
  completion_menu_label = 'C';

  init_options = {
    cache = {
      directory = cache_dir;
    };
    cacheDirectory = cache_dir;
  };

  settings_scopes = {'ccls'};
})
