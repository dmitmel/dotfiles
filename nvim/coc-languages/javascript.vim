call extend(g:dotfiles_coc_extensions, {'coc-tsserver': 1, 'coc-eslint': 1, 'coc-prettier': 1})
let s:filetypes = {'javascript': 1, 'javascriptreact': 1, 'typescript': 1, 'typescriptreact': 1}
call extend(g:dotfiles_coc_filetypes, s:filetypes)

let g:coc_user_config['eslint'] = {
\ 'filetypes': keys(s:filetypes),
\ 'autoFixOnSave': v:true,
\ }

" See <https://github.com/dmitmel/eslint-config-dmitmel/blob/v8.2.0/prettier.config.js>
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
\ 'bracketSameLine': v:true,
\ 'arrowParens': 'always',
\ 'proseWrap': 'preserve',
\ 'disableSuccessMessage': v:true,
\ }

let g:coc_user_config['snippets.extends.typescript'] = ['javascript']
let g:coc_user_config['snippets.extends.javascriptreact'] = ['javascript']
let g:coc_user_config['snippets.extends.typescriptreact'] = ['typescript', 'javascriptreact']
