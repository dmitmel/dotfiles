-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/eslint.lua>
-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/eslint.lua>

---@type dotfiles.lsp.Config
return {
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  -- <https://eslint.org/docs/user-guide/configuring/configuration-files#configuration-file-formats>
  root_markers = {
    '.eslintrc.js',
    '.eslintrc.cjs',
    '.eslintrc.yaml',
    '.eslintrc.yml',
    '.eslintrc.json',
    'package.json',
    '.git',
  },

  settings = {
    format = false,
  },

  -- TODO
  -- before_init = function(_, config)
  --   local settings = config.settings --[[@as any]]
  --   local eslint = settings.eslint
  --   if type(eslint) == 'table' then
  --     for k in pairs(settings) do
  --       settings[k] = nil
  --     end
  --     for k, v in pairs(eslint) do
  --       settings[k] = v
  --     end
  --   end
  -- end,
}
