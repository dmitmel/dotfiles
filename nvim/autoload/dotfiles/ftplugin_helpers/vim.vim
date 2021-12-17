function! dotfiles#ftplugin_helpers#vim#autoload_prefix() abort
  let path = expand('%:p')
  if dotfiles#utils#ends_with(path, '.vim')
    let path = has('win32') ? tr(path, '\', '/') : path
    for dir in dotfiles#utils#list_runtime_paths()
      let dir = (has('win32') ? tr(dir, '\', '/') : dir) . '/autoload/'
      if dotfiles#utils#starts_with(path, dir)
        return tr(path[len(dir) : -5], '/', '#') . '#'
      endif
    endfor
  endif
  return ''
endfunction
