let b:dotfiles_prose_mode = 1

call pencil#init()

let b:indentLine_enabled = v:false
let b:indent_blankline_enabled = v:false

call dotfiles#utils#undo_ftplugin_hook('unlet! b:indentLine_enabled b:indent_blankline_enabled b:dotfiles_prose_mode')
