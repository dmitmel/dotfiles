local utils = require('dotfiles.utils')

---@type dotfiles.lsp.Config
return {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },

  settings = {
    ruff = {
      configuration = utils.script_relative('../../../ruff.toml'),
      configurationPreference = 'filesystemFirst',
    },
  },

  build_settings = function(ctx) ctx.settings:merge(ctx.new_settings:pick({ 'ruff' })) end,

  on_new_config = function(config, root_dir, igniter)
    config.init_options = config.init_options or {}
    config.init_options.settings = igniter:resolve_settings(root_dir, 'workspace'):get('ruff')
  end,
}
