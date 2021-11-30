-- <https://github.com/neoclide/coc-yaml/blob/master/src/index.ts>

local lspconfig = require('lspconfig')
local lsp_global_settings = require('dotfiles.lsp.global_settings')

-- <https://github.com/redhat-developer/yaml-language-server/blob/0.22.0/src/languageserver/handlers/settingsHandlers.ts#L184-L200>
local janky_schemas = {}
for _, schema in pairs(lsp_global_settings.JSON_SCHEMAS_CATALOG) do
  local matches = janky_schemas[schema.url]
  if matches == nil then
    matches = {}
    janky_schemas[schema.url] = matches
  end
  for _, file_match in ipairs(schema.fileMatch or {}) do
    if vim.endswith(file_match, '.yml') or vim.endswith(file_match, '.yaml') then
      table.insert(matches, file_match)
    end
  end
end

lspconfig['yamlls'].setup({
  completion_menu_label = 'YAML';

  settings_scopes = {'yaml', 'http'};
  settings = {
    yaml = {
      format = {
        enable = false;
      };
      schemaStore = {
        enable = false;
        url = '';  -- Workaround for a crash, basically.
      };
      schemas = janky_schemas;
    };
  };
})
