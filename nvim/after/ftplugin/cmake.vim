setlocal iskeyword+=-
call dotutils#ftplugin_undo_set('&iskeyword')
exe dotutils#ftplugin_set('&comments', ':#')
exe dotutils#ftplugin_set('&commentstring', '#%s')
