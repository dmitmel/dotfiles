let s:filetypes = {'c': 1, 'cpp': 1, 'objc': 1, 'objcpp': 1}
call extend(g:dotfiles_coc_filetypes, s:filetypes)

let g:coc_user_config['languageserver.ccls'] = {
\ 'filetypes': keys(s:filetypes),
\ 'command': 'ccls',
\ 'rootPatterns': ['.ccls', 'compile_commands.json', '.vim/', '.git/', '.hg/'],
\ 'initializationOptions': {
\   'cache.directory': tempname(),
\   },
\ }

" let g:coc_user_config['languageserver.clangd'] = {
" \ 'filetypes': keys(s:filetypes),
" \ 'command': 'clangd',
" \ 'rootPatterns': ['compile_flags.txt', 'compile_commands.json', '.vim/', '.git/', '.hg/'],
" \ }
