nnoremap <buffer> <F5> <Cmd>source %<CR>

call dotfiles#utils#undo_ftplugin_hook('exe "silent! nunmap <buffer> <F5>"')
