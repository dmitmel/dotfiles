-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/html.lua>
-- <https://github.com/neoclide/coc-html/blob/master/src/index.ts>
-- <https://github.com/microsoft/vscode/blob/main/extensions/html-language-features/server/src/htmlServer.ts>

---@type dotfiles.lsp.Config
local config = {
  cmd = require('dotfiles.lsp_extras').find_vscode_server({
    npm_exe = 'vscode-html-language-server',
    archlinux_exe = 'vscode-html-languageserver',
    vscode_script = 'extensions/html-language-features/server/dist/node/htmlServerMain.js',
    args = { '--stdio' },
  }),
  filetypes = { 'html', 'templ' },
  root_markers = { 'package.json' },

  init_options = {
    embeddedLanguages = { css = true, javascript = true },
    configurationSection = { 'html', 'css', 'javascript' },
  },
}

return config
