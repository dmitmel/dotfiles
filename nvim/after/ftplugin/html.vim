let b:runfileprg = ':Open'
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n unlet! b:runfileprg"
