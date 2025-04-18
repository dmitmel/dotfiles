source <sfile>:h/typescript.vim

call dotutils#add_snippets_extra_scopes(['typescript', 'javascriptreact'])

call dotutils#undo_ftplugin_hook('unlet! b:dotfiles_snippets_extra_scopes')
