-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/yamlls.lua>
-- <https://github.com/neoclide/coc-yaml/blob/master/src/index.ts>
-- <https://github.com/redhat-developer/yaml-language-server/blob/0.22.0/src/languageserver/handlers/settingsHandlers.ts#L184-L200>

---@type dotfiles.lsp.Config
local config = {
  cmd = { 'yaml-language-server', '--stdio' },
  filetypes = { 'yaml' },

  settings = {
    -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
    redhat = { telemetry = { enabled = false } },
    yaml = {
      schemaStore = { enable = false, url = '' }, -- Workaround for a crash, basically.
      schemas = {},
    },
  },

  lazy_settings = function(cfg)
    vim.list_extend(cfg.settings['yaml']['schemas'], require('schemastore').yaml.schemas())
  end,
}

return config
