function dotfiles#utils#array_remove_element(array, element)
  let l:index = index(a:array, a:element)
  if l:index >= 0
    call remove(a:array, l:index)
  endif
endfunction
