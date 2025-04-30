setlocal matchpairs-=<:>
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n setlocal matchpairs<"
