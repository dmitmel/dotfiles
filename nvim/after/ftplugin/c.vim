setlocal commentstring=//%s

setlocal comments-=://
setlocal comments+=:///,://

call dotfiles#utils#undo_ftplugin_hook('setlocal comments< commentstring<')
