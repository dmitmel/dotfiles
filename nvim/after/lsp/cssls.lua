-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/cssls.lua>
-- <https://github.com/neoclide/coc-css/blob/master/src/index.ts>
-- <https://github.com/microsoft/vscode/blob/main/extensions/css-language-features/server/src/cssServer.ts>

---@type dotfiles.lsp.Config
local config = {
  cmd = require('dotfiles.lsp_extras').find_vscode_server({
    npm_exe = 'vscode-css-language-server',
    archlinux_exe = 'vscode-css-languageserver',
    vscode_script = 'extensions/css-language-features/server/dist/node/cssServerMain.js',
    args = { '--stdio' },
  }),
  filetypes = { 'css', 'less', 'sass', 'scss', 'wxss' },
  root_markers = { 'package.json' },

  init_options = {
    provideFormatter = false,
  },
}

return config
