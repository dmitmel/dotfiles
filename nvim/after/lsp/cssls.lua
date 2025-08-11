-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/cssls.lua>
-- <https://github.com/neoclide/coc-css/blob/master/src/index.ts>
-- <https://github.com/microsoft/vscode/blob/main/extensions/css-language-features/server/src/cssServer.ts>

---@type dotfiles.lsp.Config
return {
  cmd = { 'vscode-css-language-server', '--stdio' },
  filetypes = { 'css', 'less', 'sass', 'scss' },
  root_markers = { 'package.json', '.git' },

  init_options = {
    provideFormatter = false,
  },

  build_settings = function(ctx)
    ctx.settings:merge(ctx.new_settings:pick({ 'css', 'less', 'scss' }))
  end,
}
