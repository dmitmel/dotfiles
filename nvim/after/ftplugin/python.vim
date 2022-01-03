let b:delimitMate_nesting_quotes = ['"', "'"]
let b:runfileprg = 'python -- %'

call dotfiles#utils#undo_ftplugin_hook('unlet! b:delimitMate_nesting_quotes b:runfileprg')
