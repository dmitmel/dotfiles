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

function! dotfiles#utils#push_qf_list(opts, ...)
  if a:0 > 1
    throw 'Too many arguments for function'
  endif
  let custom_opts = get(a:000, 0, {})
  let loclist_window = get(custom_opts, 'loclist_window', 0)
  let action = get(custom_opts, 'action', ' ')
  let auto_open = get(custom_opts, 'auto_open', 1)
  if loclist_window
    call setloclist(loclist_window, [], action, a:opts)
    if auto_open | call qf#OpenLoclist() | endif
  else
    call setqflist([], action, a:opts)
    if auto_open | call qf#OpenQuickfix() | endif
  endif
endfunction
