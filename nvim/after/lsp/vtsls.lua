-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/vtsls.lua>
-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/vtsls.lua>

---@type dotfiles.lsp.Config
return {
  cmd = { 'vtsls', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },

  settings_sections = { 'tsserver', 'javascript', 'typescript', 'vtsls' },
  settings = { typescript = {} },

  before_init = function(_, config)
    local settings = config.settings --[[@as any]]
    local tsserver = settings.tsserver
    if type(tsserver) == 'table' then
      settings.typescript = vim.tbl_deep_extend('keep', settings.typescript or {}, tsserver)
      settings.vtsls = vim.tbl_deep_extend('keep', settings.vtsls or {}, {
        autoUseWorkspaceTsdk = tsserver.useLocalTsdk,
      })
    end
  end,

  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}
