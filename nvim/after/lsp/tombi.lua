--- <https://tombi-toml.github.io/tombi/docs/reference/difference-taplo/>
-- XXX: Currently, this language server does not handle stop request correctly.

local utils = require('dotfiles.utils')

---@type dotfiles.lsp.Config
return {
  cmd = { 'tombi', 'lsp' },
  filetypes = { 'toml' },
  root_markers = { 'tombi.toml', 'pyproject.toml', '.git' },

  build_settings = function(ctx)
    -- NOTE: This list must consist of objects of the following shape:
    -- { fileMatch: string[], uri: string }
    -- Notice how it is `uri` and not `url`, and that `fileMatch` is always a
    -- list! If an entry is invalid, tombi` will reject it without any sort of
    -- indication! This took me a long time and lots of debugging to figure out.
    local value = ctx.new_settings:get('toml.schemas')
    if type(value) == 'table' and utils.is_list(value) then
      ctx.settings:update('toml.schemas', function(prev) return utils.concat_lists(prev, value) end)
    end
  end,

  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false

    for _, association in ipairs(vim.tbl_get(client.settings, 'toml', 'schemas') or {}) do
      client:notify('tombi/associateSchema', association)
    end
  end,
}
