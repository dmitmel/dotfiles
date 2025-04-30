setlocal matchpairs-=<:>
let b:runfileprg = 'node -- %'
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n" .
\ 'setlocal matchpairs< | unlet! b:runfileprg'
