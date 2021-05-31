let s:filetypes = ['c', 'cpp', 'objc', 'objcpp']
let g:coc_filetypes += s:filetypes

let g:coc_user_config['languageserver.ccls'] = {
\ 'filetypes': s:filetypes,
\ 'command': 'ccls',
\ 'rootPatterns': ['.ccls', 'compile_commands.json', '.vim/', '.git/', '.hg/'],
\ 'initializationOptions': {
\   'cache.directory': tempname(),
\   },
\ }

" let g:coc_user_config['languageserver.clangd'] = {
" \ 'filetypes': s:filetypes,
" \ 'command': 'clangd',
" \ 'rootPatterns': ['compile_flags.txt', 'compile_commands.json', '.vim/', '.git/', '.hg/'],
" \ }
