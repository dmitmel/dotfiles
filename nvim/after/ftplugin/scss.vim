source <sfile>:h/css.vim

let &l:makeprg = 'sass -- %:S:%:S.css'

call dotfiles#utils#undo_ftplugin_hook('setlocal makeprg<')
