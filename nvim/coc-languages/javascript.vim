let g:coc_global_extensions += ['coc-tsserver', 'coc-eslint', 'coc-prettier']
let s:filetypes = ['javascript', 'javascriptreact', 'typescript', 'typescriptreact']
let g:coc_filetypes += s:filetypes
let g:coc_user_config['eslint'] = {
\ 'filetypes': s:filetypes,
\ 'autoFixOnSave': v:true,
\ }
let g:coc_user_config['prettier'] = {
\ 'singleQuote': v:true,
\ 'trailingComma': 'all',
\ 'jsxBracketSameLine': v:true,
\ 'eslintIntegration': v:true,
\ 'disableSuccessMessage': v:true
\ }
