source <sfile>:h/typescript.vim

call dotfiles#utils#add_snippets_extra_scopes(['typescript', 'javascriptreact'])

call dotfiles#utils#undo_ftplugin_hook('unlet! b:dotfiles_snippets_extra_scopes')
