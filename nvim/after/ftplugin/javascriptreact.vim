source <sfile>:h/javascript.vim

call dotfiles#utils#add_snippets_extra_scopes(['javascript'])

call dotfiles#utils#undo_ftplugin_hook('unlet! b:dotfiles_snippets_extra_scopes')
