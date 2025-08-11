-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/jsonls.lua>
-- <https://github.com/neoclide/coc-json/blob/master/src/index.ts>
-- <https://github.com/microsoft/vscode/blob/main/extensions/json-language-features/client/src/jsonClient.ts>

local utils = require('dotfiles.utils')

---@type dotfiles.lsp.Config
return {
  cmd = { 'vscode-json-language-server', '--stdio' },
  filetypes = { 'json', 'jsonc', 'json5' },

  init_options = {
    provideFormatter = false,
  },

  build_settings = function(ctx)
    local merger = { json = { schemas = utils.concat_lists } }

    if ctx.step == 'lspconfig' then
      local schemas = {}
      vim.list_extend(schemas, require('schemastore').json.schemas())

      -- See <https://github.com/folke/neoconf.nvim/blob/b516f1ca1943de917e476224e7aa6b9151961991/lua/neoconf/plugins/jsonls.lua>.
      if pcall(require, 'neoconf') then
        local options = require('neoconf.config').get({ global = true, ['local'] = false })
        local schema = require('neoconf.schema').get()

        table.insert(schemas, {
          fileMatch = { options.global_settings, options.local_settings },
          schema = schema:get(),
        })

        require('neoconf.import').on_schemas(schema, schemas)
      end

      ctx.settings:merge({ json = { schemas = schemas } }, merger)
    end

    if vim.endswith(ctx.step, '_local') and ctx.scope_uri then
      local folder = require('dotfiles.lsp_extras').find_workspace_folder(ctx.scope_uri, ctx.client)
      if folder then
        local schemas = ctx.new_settings:get('json.schemas', {}) --[[@as table[] ]]
        for idx in ipairs(schemas) do
          ctx.new_settings:set({ 'json', 'schemas', idx, 'folderUri' }, folder.uri)
        end
      end
    end

    ctx.settings:merge(ctx.new_settings:pick({ 'json', 'http' }), merger)
  end,
}
