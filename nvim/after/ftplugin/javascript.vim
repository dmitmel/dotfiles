setlocal matchpairs-=<:>

let b:runfileprg = 'node -- %'

call dotfiles#utils#undo_ftplugin_hook('setlocal matchpairs< | unlet b:runfileprg')
