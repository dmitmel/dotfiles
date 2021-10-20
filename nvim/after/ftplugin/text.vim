call pencil#init()

let b:indentLine_enabled = v:false
let b:indent_blankline_enabled = v:false

" Reset these mappings to their default function (jumping over sentences):
noremap <buffer> ( (
noremap <buffer> ) )

call dotfiles#utils#undo_ftplugin_hook('exe "silent! unmap <buffer> (" | exe "silent! unmap <buffer> )"')
