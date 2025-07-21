-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/jsonls.lua>
-- <https://github.com/neoclide/coc-json/blob/master/src/index.ts>
-- <https://github.com/microsoft/vscode/blob/main/extensions/json-language-features/client/src/jsonClient.ts>

---@type dotfiles.lsp.Config
return {
  cmd = { 'vscode-json-language-server', '--stdio' },
  filetypes = { 'json', 'jsonc', 'json5' },

  init_options = {
    provideFormatter = false,
  },

  settings_sections = { 'json', 'http' },
  settings = { json = { schemas = {} } },

  on_new_config = function(config)
    vim.list_extend(config.settings['json']['schemas'], require('schemastore').json.schemas())
  end,
}
