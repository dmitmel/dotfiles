function! dotfiles#utils#array_remove_element(array, element) abort
  let index = index(a:array, a:element)
  if index >= 0
    call remove(a:array, index)
  endif
endfunction

function! dotfiles#utils#undo_ftplugin_hook(cmd) abort
  if exists('b:undo_ftplugin')
    let b:undo_ftplugin .= ' | ' . a:cmd
  else
    let b:undo_ftplugin = a:cmd
  endif
endfunction
