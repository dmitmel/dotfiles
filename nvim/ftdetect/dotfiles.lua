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
  },
  pattern = {
    ['.*/assets/.*%.json%.patch'] = 'json',
    ['.*/etc/fonts/.*%.conf'] = 'xml',
    ['.*/fontconfig/.*%.conf'] = 'xml',
    ['.*/snippets/.*%.json'] = 'jsonc',
  },
})
