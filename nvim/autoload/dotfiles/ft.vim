" Utilities for my ftplugins and indent plugins.

function! dotfiles#ft#undo(...) abort
  let commands = [get(b:, 'undo_ftplugin', '')] + a:000
  let b:undo_ftplugin = join(filter(commands, '!empty(v:val)'), ' | ')
endfunction

function! dotfiles#ft#indent_undo(...) abort
  let commands = [get(b:, 'undo_indent', '')] + a:000
  let b:undo_indent = join(filter(commands, '!empty(v:val)'), ' | ')
endfunction

function! dotfiles#ft#undo_map(mode, mappings) abort
  for lhs in type(a:mappings) != type([]) ? [a:mappings] : a:mappings
    call dotfiles#ft#undo('silent! ' . a:mode . 'unmap <buffer> ' . lhs)
  endfor
endfunction

function! dotfiles#ft#setlocal(args) abort
  let name = matchstr(a:args, '\C^\%(no\)\=\zs[a-z]\+')
  if empty(name) | throw 'need an option name' | endif
  call dotfiles#ft#undo('setl ' . name . '<')
  " The caller has to `:execute` this line, so that `verbose set {option}?`
  " displays an appropriate location.
  return 'setl ' . escape(a:args, ' \"|')
endfunction

function! dotfiles#ft#set(name, value) abort
  if a:name[0] ==# '&'
    call dotfiles#ft#undo('setl ' . a:name[1:] . '<')
    call setbufvar('%', a:name, a:value)
  else
    call dotfiles#ft#undo('unlet! b:' . a:name)
    let b:{a:name} = a:value
  endif
endfunction
