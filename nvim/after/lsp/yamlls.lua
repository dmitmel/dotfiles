-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/yamlls.lua>
-- <https://github.com/neoclide/coc-yaml/blob/master/src/index.ts>
-- <https://github.com/redhat-developer/yaml-language-server/blob/0.22.0/src/languageserver/handlers/settingsHandlers.ts#L184-L200>

---@type dotfiles.lsp.Config
return {
  cmd = { 'yaml-language-server', '--stdio' },
  filetypes = { 'yaml' },

  settings_sections = { 'yaml', 'http', 'redhat' },
  settings = {
    -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
    redhat = { telemetry = { enabled = false } },
    yaml = {
      schemaStore = { enable = false, url = '' }, -- Workaround for a crash, basically.
      schemas = vim.empty_dict(),
    },
  },

  on_new_config = function(config)
    local settings_schemas = config.settings['yaml']['schemas']
    for k, v in pairs(require('schemastore').yaml.schemas()) do
      settings_schemas[k] = v
    end
  end,
}
