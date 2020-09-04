let g:coc_filetypes += ['rust']
let g:coc_global_extensions += ['coc-rust-analyzer']
let g:coc_user_config['rust-analyzer'] = {
\ 'serverPath': 'rust-analyzer',
\ 'inlayHints': {
\   'chainingHints': v:false,
\   },
\ 'checkOnSave': {
\    'command': 'clippy'
\   },
\ }

" let g:coc_global_extensions += ['coc-rls']
" let g:coc_user_config['rust'] = { 'clippy_preference': 'on' }
