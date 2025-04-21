vim.filetype.add({
  extension = {
    snippets = 'snippets',
  },
  filename = {
    ['.clangd'] = 'yaml',
    ['.vimspector.json'] = 'jsonc',
    ['.latexmkrc'] = 'perl',
  },
  pattern = {
    ['.*/assets/.*%.json%.patch'] = 'json',
    ['.*/etc/fonts/.*%.conf'] = 'xml',
    ['.*/fontconfig/.*%.conf'] = 'xml',
  },
})
