-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/ts_ls.lua>
-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/ts_ls.lua>
-- <https://github.com/typescript-language-server/typescript-language-server/blob/master/docs/configuration.md>

---@type dotfiles.lsp.Config
return {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json' },
  settings_sections = { 'tsserver', 'javascript', 'typescript' },

  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}
