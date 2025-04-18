source <sfile>:h/css.vim

let &l:makeprg = 'sass -- %:S:%:S.css'

call dotutils#undo_ftplugin_hook('setlocal makeprg<')
