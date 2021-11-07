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

" Opens file or URL with a system program.
function! dotfiles#utils#open_url(path) abort
  " HACK: The 2nd parameter of this function is called 'remote', it tells
  " whether to open a remote (1) or local (0) file. However, it doesn't work as
  " expected in this context, because it uses the 'gf' command if it's opening
  " a local file (because this function was designed to be called from the 'gx'
  " command). BUT, because this function only compares the value of the
  " 'remote' parameter to 1, I can pass any other value, which will tell it to
  " open a local file and ALSO this will ignore an if-statement which contains
  " the 'gf' command.
  return netrw#BrowseX(a:path, 2)
endfunction

function! dotfiles#utils#push_qf_list(opts) abort
  let loclist_window = get(a:opts, 'dotfiles_loclist_window', 0)
  let action = get(a:opts, 'dotfiles_action', ' ')
  let auto_open = get(a:opts, 'dotfiles_auto_open', 1)
  if loclist_window
    call setloclist(loclist_window, [], action, a:opts)
    if auto_open | call qf#OpenLoclist() | endif
  else
    call setqflist([], action, a:opts)
    if auto_open | call qf#OpenQuickfix() | endif
  endif
endfunction
