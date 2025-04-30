setlocal keywordprg<
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n setlocal keywordprg<"
