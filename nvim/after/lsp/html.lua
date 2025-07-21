-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/html.lua>
-- <https://github.com/neoclide/coc-html/blob/master/src/index.ts>
-- <https://github.com/microsoft/vscode/blob/main/extensions/html-language-features/server/src/htmlServer.ts>

---@type dotfiles.lsp.Config
return {
  cmd = { 'vscode-html-language-server', '--stdio' },
  filetypes = { 'html' },
  root_markers = { 'package.json', '.git' },

  settings_sections = { 'html', 'css', 'javascript' },
  init_options = {
    embeddedLanguages = { css = true, javascript = true },
    configurationSection = { 'html', 'css', 'javascript' },
    provideFormatter = false,
  },
}
