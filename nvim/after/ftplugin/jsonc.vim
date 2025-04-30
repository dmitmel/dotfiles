setlocal comments&vim commentstring=//%s
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n setlocal comments< commentstring<"
