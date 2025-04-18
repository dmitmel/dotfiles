source <sfile>:h/javascript.vim

call dotutils#add_snippets_extra_scopes(['javascript'])

call dotutils#undo_ftplugin_hook('unlet! b:dotfiles_snippets_extra_scopes')
