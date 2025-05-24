setlocal matchpairs-=<:>
call dotutils#ftplugin_undo_set('&matchpairs')
call dotutils#ftplugin_set('runfileprg', 'node -- %')
