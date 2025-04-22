vim.filetype.add({
  filename = {
    ['.clangd'] = 'yaml',
    ['.vimspector.json'] = 'jsonc.vimspector',
    ['.latexmkrc'] = 'perl',
  },
  pattern = {
    ['.*/assets/.*%.json%.patch'] = 'json',
    ['.*/etc/fonts/.*%.conf'] = 'xml',
    ['.*/fontconfig/.*%.conf'] = 'xml',
    ['.*/snippets/.*%.json'] = 'jsonc.snippets',
  },
})
