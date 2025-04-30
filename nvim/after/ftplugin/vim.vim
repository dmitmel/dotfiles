let b:runfileprg = ':source %'
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n unlet! b:runfileprg"
