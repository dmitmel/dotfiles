-- <https://github.com/MaskRay/vscode-ccls/blob/master/src/serverContext.ts>

local lsp_ignition = require('dotfiles.lsp.ignition')
local lspconfig_utils = require('lspconfig.util')

local cache_dir = vim.call('dotfiles#paths#xdg_cache_home') .. '/ccls'
lsp_ignition.setup_config('ccls', {
  cmd = {'ccls'};
  filetypes = {'c', 'cpp', 'objc', 'objcpp'};
  -- root_dir = lspconfig_utils.root_pattern('compile_commands.json', '.ccls');
  single_file_support = false;
  completion_menu_label = 'C';

  init_options = {
    cache = {
      directory = cache_dir;
    };
    cacheDirectory = cache_dir;
  };

  settings_scopes = {'ccls'};
})
