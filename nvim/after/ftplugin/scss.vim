source <sfile>:h/css.vim
exe dotutils#ftplugin_set('&makeprg', 'sass -- %:S:%:S.css')
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n setlocal makeprg<"
