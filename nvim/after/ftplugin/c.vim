exe dotfiles#ft#set('&commentstring', '//%s')

function! s:patch_c_comments() abort
  " The regex matches a comma not preceded by a backslash.
  let comments = split(&comments, '\\\@1<!,')

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

  exe dotfiles#ft#set('&comments', join(comments, ','))
endfunction
call s:patch_c_comments()

call dotfiles#ft#set('indent_motion_exclude_lines', join([
\ '^\s*#\s*\%(if\|ifdef\|ifndef\|elif\|else\|endif\)\>',
\ '^\s*\I\i*\s*:\s*$',
\ ], '\|'))
