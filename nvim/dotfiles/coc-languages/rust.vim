call extend(g:dotfiles_coc_extensions, {'coc-rust-analyzer': 1})
call extend(g:dotfiles_coc_filetypes, {'rust': 1})

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

" call extend(g:dotfiles_coc_extensions, {'coc-rls': 1})
"
" let g:coc_user_config['rust'] = { 'clippy_preference': 'on' }
