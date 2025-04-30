let b:dotfiles_prose_mode = 1

call pencil#init()
silent! iunmap <buffer> <up>
silent! iunmap <buffer> <down>

let b:indentLine_enabled = v:false
let b:indent_blankline_enabled = v:false

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n" .
\ 'unlet! b:indentLine_enabled b:indent_blankline_enabled b:dotfiles_prose_mode'
