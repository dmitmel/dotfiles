setlocal iskeyword+=-
setlocal comments=:# commentstring=#%s

call dotutils#undo_ftplugin_hook('setlocal iskeyword< comments< commentstring<')
