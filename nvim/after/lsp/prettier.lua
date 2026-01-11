local utils = require('dotfiles.utils')

-- All VSCode language IDs supported by Prettier can be obtained with:
-- $ prettier --support-info | jq '[.languages[].vscodeLanguageIds[]] | unique'
-- Note that not every one of those is a valid filetype in Vim.

-- <https://github.com/prettier/prettier/blob/3.6.0/src/config/prettier-config/config-searcher.js#L11-L32>
local CONFIG_FILE_NAMES = utils.list_to_set({
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
})

local PRETTIER_LS_DIR = utils.script_relative('../../prettier-language-server')

---@type dotfiles.lsp.Config
return {
  cmd = { 'node', PRETTIER_LS_DIR .. '/main.js', '--stdio' },

  -- stylua: ignore
  filetypes = {
    'javascript', 'javascriptreact', 'typescript', 'typescriptreact',
    'css', 'less', 'sass', 'scss', 'json', 'jsonc', 'json5', 'yaml',
    'html', 'markdown', 'mdx', 'vue', 'graphql'
  },

  root_markers = {
    function(name) return CONFIG_FILE_NAMES[name] ~= nil end,
    'package.json',
    '.editorconfig',
    '.git',
  },

  build_settings = function(ctx) ctx.settings:merge(ctx.new_settings:pick({ 'prettier' })) end,

  on_new_config = function()
    if vim.fn.isdirectory(PRETTIER_LS_DIR .. '/node_modules') == 0 then
      local pm = utils.find({ 'yarn', 'npm' }, function(pm) return vim.fn.executable(pm) ~= 0 end)
      if pm ~= nil then
        vim.cmd(('!cd -- %s && %s install'):format(vim.fn.shellescape(PRETTIER_LS_DIR, true), pm))
      end
    end
  end,
}
