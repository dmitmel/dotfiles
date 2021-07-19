call pencil#init()

if exists(':IndentLinesDisable')
  IndentLinesDisable
elseif exists(':IndentBlanklineDisable')
  IndentBlanklineDisable
endif

" Reset these mappings to their default function (jumping over sentences):
noremap <buffer> ( (
noremap <buffer> ) )

call dotfiles#utils#undo_ftplugin_hook('exe "unmap <buffer> (" | exe "unmap <buffer> )"')
