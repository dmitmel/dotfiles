let g:coc_global_extensions += ['coc-tsserver', 'coc-eslint', 'coc-prettier']
let g:coc_filetypes += ['javascript', 'javascript.jsx', 'typescript', 'typescript.jsx']
let g:coc_user_config['eslint'] = {
\ 'filetypes': ['javascript', 'javascriptreact'],
\ 'autoFixOnSave': v:true,
\ }
let g:coc_user_config['prettier'] = {
\ 'singleQuote': v:true,
\ 'trailingComma': 'all',
\ 'jsxBracketSameLine': v:true,
\ 'eslintIntegration': v:true,
\ 'disableSuccessMessage': v:true
\ }
