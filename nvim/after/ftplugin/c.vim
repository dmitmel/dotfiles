setlocal commentstring=//%s

function! s:patch_c_comments() abort
  " The regex matches a comma not preceded by a backslash.
  let comments = split(&l:comments, '\\\@1<!,')

  let idx = index(comments, ':///')
  if idx >= 0
    call remove(comments, idx)
  else
    let idx = index(comments, '://')
    if idx < 0
      let idx = len(comments)
    endif
  endif
  call insert(comments, ':///<,://!<,:///,://!', idx)

  let &l:comments = join(comments, ',')
endfunction
call s:patch_c_comments()

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n setlocal comments< commentstring<"
