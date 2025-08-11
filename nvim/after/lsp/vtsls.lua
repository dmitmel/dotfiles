-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/vtsls.lua>
-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/vtsls.lua>

---@type dotfiles.lsp.Config
return {
  cmd = { 'vtsls', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },

  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,

  build_settings = function(ctx)
    ctx.settings:merge(ctx.new_settings:pick({ 'javascript', 'typescript', 'js/ts', 'vtsls' }))
  end,
}
