-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/yamlls.lua>
-- <https://github.com/neoclide/coc-yaml/blob/master/src/index.ts>
-- <https://github.com/redhat-developer/yaml-language-server/blob/0.22.0/src/languageserver/handlers/settingsHandlers.ts#L184-L200>

---@type dotfiles.lsp.Config
return {
  cmd = { 'yaml-language-server', '--stdio' },
  filetypes = { 'yaml' },

  settings = {
    yaml = {
      schemaStore = { enable = false, url = '' }, -- Workaround for a crash, basically.
    },
  },

  build_settings = function(ctx)
    if ctx.step == 'lspconfig' then
      ctx.settings:merge({
        yaml = { schemas = require('schemastore').yaml.schemas() },
      })
    end
    ctx.settings:merge(ctx.new_settings:pick({ 'yaml', 'http' }))
  end,
}
