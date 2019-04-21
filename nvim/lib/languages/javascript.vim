call coc#add_extension('coc-tsserver', 'coc-eslint', 'coc-prettier')
let g:coc_filetypes += ['javascript', 'javascript.jsx', 'typescript', 'typescript.jsx']
call coc#config('eslint', {
\ 'filetypes': ['javascript', 'javascriptreact', 'typescript', 'typescriptreact'],
\ 'autoFixOnSave': v:true,
\ })
call coc#config('prettier', {
\ 'singleQuote': v:true,
\ 'trailingComma': 'all',
\ 'jsxBracketSameLine': v:true,
\ 'eslintIntegration': v:true,
\ })
