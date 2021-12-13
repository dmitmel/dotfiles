-- <https://github.com/neoclide/coc-yaml/blob/master/src/index.ts>

local lsp_ignition = require('dotfiles.lsp.ignition')
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

-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/yamlls.lua>
lsp_ignition.setup_config('yamlls', {
  cmd = {'yaml-language-server', '--stdio'};
  filetypes = {'yaml', 'yaml.docker-compose'};
  single_file_support = true;
  completion_menu_label = 'YAML';

  settings_scopes = {'yaml', 'http'};
  settings = {
    redhat = {
      -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
      telemetry = { enabled = true; };
    };
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
