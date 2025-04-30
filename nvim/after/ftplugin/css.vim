setlocal iskeyword+=-
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n setlocal iskeyword<"
