setlocal noexpandtab nofoldenable
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n setlocal expandtab< foldenable<"
