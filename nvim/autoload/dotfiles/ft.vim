" Utilities for my ftplugins and indent plugins.

function! dotfiles#ft#undo(...) abort
  let commands = [get(b:, 'undo_ftplugin', '')] + a:000
  let b:undo_ftplugin = join(filter(commands, '!empty(v:val)'), ' | ')
endfunction

function! dotfiles#ft#indent_undo(...) abort
  let commands = [get(b:, 'undo_indent', '')] + a:000
  let b:undo_indent = join(filter(commands, '!empty(v:val)'), ' | ')
endfunction

function! dotfiles#ft#undo_set(name) abort
  call dotfiles#ft#undo(a:name =~# '^&[a-z]\+$' ? ('setlocal ' . a:name[1:] . '<') : ('unlet! b:' . a:name))
endfunction

function! dotfiles#ft#undo_map(mode, mappings) abort
  for lhs in type(a:mappings) != type([]) ? [a:mappings] : a:mappings
    call dotfiles#ft#undo('silent! ' . a:mode . 'unmap <buffer> ' . lhs)
  endfor
endfunction

function! dotfiles#ft#set(name, value) abort
  call dotfiles#ft#undo_set(a:name)
  if a:name =~# '^&[a-z]\+$'
    " The caller has to `:execute` this line, so that `verbose set {option}?`
    " displays an appropriate location.
    return 'let &l:' . a:name[1:] . ' = ' . json_encode(a:value)
  else
    " This validates the correctness of variable names for us.
    let b:{a:name} = a:value
    return ''
  endif
endfunction
