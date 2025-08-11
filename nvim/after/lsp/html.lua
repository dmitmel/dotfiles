-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/html.lua>
-- <https://github.com/neoclide/coc-html/blob/master/src/index.ts>
-- <https://github.com/microsoft/vscode/blob/main/extensions/html-language-features/server/src/htmlServer.ts>

---@type dotfiles.lsp.Config
return {
  cmd = { 'vscode-html-language-server', '--stdio' },
  filetypes = { 'html' },
  root_markers = { 'package.json', '.git' },

  init_options = {
    embeddedLanguages = { css = true, javascript = true },
    configurationSection = { 'html', 'css', 'javascript' },
    provideFormatter = false,
  },

  build_settings = function(ctx)
    ctx.settings:merge(ctx.new_settings:pick({ 'html', 'css', 'javascript', 'js/ts' }))
  end,
}
