call extend(g:dotfiles_coc_extensions, {'coc-json': 1, 'coc-prettier': 1})
call extend(g:dotfiles_coc_filetypes, {'json': 1, 'json5': 1})

let g:coc_user_config['json.schemas'] = [
\ {
\   'fileMatch': ['*.json.patch'],
\   'url': 'https://raw.githubusercontent.com/dmitmel/ultimate-crosscode-typedefs/master/json-schemas/patch-steps.json',
\ },
\ {
\   'fileMatch': ['*/snippets/*.json'],
\   'url': 'https://raw.githubusercontent.com/Yash-Singh1/vscode-snippets-json-schema/main/schema.json',
\ },
\ {
\   'fileMatch': ['*.vimspector.json'],
\   'url': 'https://puremourning.github.io/vimspector/schema/vimspector.schema.json',
\ },
\]
