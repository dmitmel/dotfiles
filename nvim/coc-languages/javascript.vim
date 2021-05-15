let g:coc_global_extensions += ['coc-tsserver', 'coc-eslint', 'coc-prettier']
let s:filetypes = ['javascript', 'javascriptreact', 'typescript', 'typescriptreact']
let g:coc_filetypes += s:filetypes
let g:coc_user_config['eslint'] = {
\ 'filetypes': s:filetypes,
\ 'autoFixOnSave': v:true,
\ }
" See <https://github.com/dmitmel/eslint-config-dmitmel/blob/9b14f45aef7efbf333b38a06277296f5b0304484/prettier.config.js>
let g:coc_user_config['prettier'] = {
\ 'printWidth': 100,
\ 'tabWidth': 2,
\ 'useTabs': v:false,
\ 'semi': v:true,
\ 'singleQuote': v:true,
\ 'quoteProps': 'as-needed',
\ 'jsxSingleQuote': v:false,
\ 'trailingComma': 'all',
\ 'bracketSpacing': v:true,
\ 'jsxBracketSameLine': v:true,
\ 'arrowParens': 'always',
\ 'disableSuccessMessage': v:true,
\ 'proseWrap': 'always',
\ }
