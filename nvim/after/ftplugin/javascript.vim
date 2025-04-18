setlocal matchpairs-=<:>

let b:runfileprg = 'node -- %'

call dotutils#undo_ftplugin_hook('setlocal matchpairs< | unlet! b:runfileprg')
