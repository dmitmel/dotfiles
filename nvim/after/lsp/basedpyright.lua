-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/basedpyright.lua>

---@type dotfiles.lsp.Config
local config = {
  cmd = { 'basedpyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    'pyrightconfig.json',
  },
}

return config
