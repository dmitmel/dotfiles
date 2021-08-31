let g:coc_filetypes += ['rust']
let g:dotfiles_coc_extensions += ['coc-rust-analyzer']
let g:coc_user_config['rust-analyzer'] = {
\ 'serverPath': 'rust-analyzer',
\ 'lens.enable': v:false,
\ 'inlayHints.typeHints': v:false,
\ 'inlayHints.chainingHints': v:false,
\ 'diagnostics.enable': v:false,
\ 'completion.autoimport.enable': v:false,
\ 'checkOnSave.command': 'clippy',
\ 'cargo.loadOutDirsFromCheck': v:true,
\ }

" let g:dotfiles_coc_extensions += ['coc-rls']
" let g:coc_user_config['rust'] = { 'clippy_preference': 'on' }
