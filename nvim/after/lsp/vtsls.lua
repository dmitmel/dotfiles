-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/vtsls.lua>
-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/vtsls.lua>

---@type dotfiles.lsp.Config
return {
  cmd = { 'vtsls', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },

  settings_sections = { 'tsserver', 'javascript', 'typescript' },
  settings = { typescript = {} },

  before_init = function(_, config)
    local settings = config.settings --[[@as any]]
    if type(settings.tsserver) == 'table' and type(settings.typescript) == 'table' then
      settings.typescript = vim.tbl_deep_extend('keep', settings.typescript, settings.tsserver)
    end
  end,

  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}
