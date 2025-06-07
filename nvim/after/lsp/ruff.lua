local utils = require('dotfiles.utils')

---@type dotfiles.lsp.Config
local config = {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml' },
  init_options = {
    settings = {
      configuration = utils.script_relative('../../../ruff.toml'),
      configurationPreference = 'filesystemFirst',
    },
  },
}

return config
