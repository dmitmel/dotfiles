if not vim.filetype then return end

vim.filetype.add({
  extension = {
    log = 'log',
    LOG = 'log',
  },
  filename = {
    ['.clangd'] = 'yaml',
    ['.vimspector.json'] = 'jsonc',
    ['.latexmkrc'] = 'perl',
    ['coc-settings.json'] = 'jsonc',
    ['pyrightconfig.json'] = 'jsonc',
    ['.luarc.json'] = 'jsonc',
  },
  pattern = {
    ['.*/assets/.*%.json%.patch'] = 'json',
    ['.*/etc/fonts/.*%.conf'] = 'xml',
    ['.*/fontconfig/.*%.conf'] = 'xml',
    ['.*/snippets/.*%.json'] = 'jsonc',
    ['.*/%.vscode/.*%.json'] = 'jsonc',
  },
})
