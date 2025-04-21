function! dotfiles#ft#vim#autoload_prefix() abort
  let path = expand('%:p')
  if dotutils#ends_with(path, '.vim')
    let path = has('win32') ? tr(path, '\', '/') : path
    for dir in dotutils#list_runtime_paths()
      let dir = (has('win32') ? tr(dir, '\', '/') : dir) . '/autoload/'
      if dotutils#starts_with(path, dir)
        return tr(path[len(dir) : -5], '/', '#') . '#'
      endif
    endfor
  endif
  return ''
endfunction
