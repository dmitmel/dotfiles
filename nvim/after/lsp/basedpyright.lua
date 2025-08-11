-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/basedpyright.lua>

---@type dotfiles.lsp.Config
return {
  cmd = { 'basedpyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    'pyrightconfig.json',
    '.git',
  },

  build_settings = function(ctx)
    ctx.settings:merge(ctx.new_settings:pick({ 'python', 'basedpyright' }))
  end,
}
