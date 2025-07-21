local utils = require('dotfiles.utils')

-- All VSCode language IDs supported by Prettier can be obtained with:
-- $ prettier --support-info | jq '[.languages[].vscodeLanguageIds[]] | unique'
-- Note that every one of those is a valid filetype in Vim.

---@type dotfiles.lsp.Config
return {
  cmd = { 'node', utils.script_relative('../../prettier-language-server/main.js'), '--stdio' },

  -- stylua: ignore
  filetypes = {
    'javascript', 'javascriptreact', 'typescript', 'typescriptreact',
    'css', 'less', 'sass', 'scss', 'json', 'jsonc', 'json5', 'yaml',
    'html', 'markdown', 'mdx', 'vue', 'graphql'
  },

  root_markers = {
    -- <https://github.com/prettier/prettier/blob/3.6.0/src/config/prettier-config/config-searcher.js#L11-L32>
    {
      '.prettierrc',
      '.prettierrc.json',
      '.prettierrc.yaml',
      '.prettierrc.yml',
      '.prettierrc.json5',
      '.prettierrc.js',
      '.prettierrc.ts',
      '.prettierrc.mjs',
      '.prettierrc.mts',
      '.prettierrc.cjs',
      '.prettierrc.cts',
      'prettier.config.js',
      'prettier.config.ts',
      'prettier.config.mjs',
      'prettier.config.mts',
      'prettier.config.cjs',
      'prettier.config.cts',
      '.prettierrc.toml',
    },
    'package.json',
    '.editorconfig',
    '.git',
  },

  settings_sections = { 'prettier' },
}
