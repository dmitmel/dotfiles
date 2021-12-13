function! dotfiles#ftplugin_helpers#vim#to_autoload_prefix(path) abort
  let path = fnamemodify(a:path, ':p')
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
