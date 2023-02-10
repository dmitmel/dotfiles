setlocal iskeyword+=-
setlocal comments=:# commentstring=#%s

call dotfiles#utils#undo_ftplugin_hook('setlocal iskeyword< comments< commentstring<')
