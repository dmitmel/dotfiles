function dotfiles#utils#array_remove_element(array, element)
  let index = index(a:array, a:element)
  if index >= 0
    call remove(a:array, index)
  endif
endfunction
