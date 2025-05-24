setlocal comments&vim
call dotutils#ftplugin_undo_set('&comments')
exe dotutils#ftplugin_set('&commentstring', '//%s')
