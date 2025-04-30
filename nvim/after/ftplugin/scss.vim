source <sfile>:h/css.vim
let &l:makeprg = 'sass -- %:S:%:S.css'
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n setlocal makeprg<"
