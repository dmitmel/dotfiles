-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/pyright.lua>
-- <https://github.com/fannheyward/coc-pyright/blob/master/src/index.ts>

---@type dotfiles.lsp.Config
local config = {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    'pyrightconfig.json',
  },

  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'workspace',
      },
    },
  },
}

return config
