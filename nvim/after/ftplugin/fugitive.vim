setlocal nofoldenable foldmethod=manual
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n setlocal foldenable< foldmethod<"
