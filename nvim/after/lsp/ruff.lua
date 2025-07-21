local utils = require('dotfiles.utils')

---@type dotfiles.lsp.Config
return {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },

  settings_sections = { 'ruff' },
  settings = {
    ruff = {
      configuration = utils.script_relative('../../../ruff.toml'),
      configurationPreference = 'filesystemFirst',
    },
  },

  before_init = function(init_params, config) init_params.settings = config.settings.ruff end,
}
