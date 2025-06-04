function! dotfiles#indent_motion#run(up) abort
  if mode(1) ==# 'no'  " Check if in the Operator mode without a |forced-motion|
    normal! V
  endif
  normal! m'
  let line = dotfiles#indent_motion#find_line(a:up)
  let col = len(matchstr(getline(line), '^\s*')) + 1
  call cursor(line, col)
endfunction

" Based on <https://github.com/kana/vim-textobj-indent/blob/deb76867c302f933c8f21753806cbf2d8461b548/autoload/textobj/indent.vim>
" A motion for moving over enclosing indentation blocks. Primarily intended
" for reverse-engineering CrossCode.
function! dotfiles#indent_motion#find_line(up) abort
  let Nextnonblank = a:up ? function('prevnonblank') : function('nextnonblank')
  let step = a:up ? -1 : 1

  let cursor_line = line('.')
  let start_line = Nextnonblank(cursor_line)
  let start_indent = indent(start_line)
  if start_line <= 0 || start_indent < 0 | return cursor_line | endif

  let line_ignore_pat = get(b:, 'indent_motion_exclude_lines', '')
  if !empty(line_ignore_pat) && getline(start_line) !~# line_ignore_pat
    let IgnoreLine = { nr -> getline(nr) =~# line_ignore_pat }
  else
    let IgnoreLine = { nr -> 0 }
  endif

  let current_line = start_line
  while 1
    let current_line = Nextnonblank(current_line + step)
    let current_indent = indent(current_line)
    if current_line <= 0 || current_indent < 0 | return start_line | endif
    if !IgnoreLine(current_line) | break | endif
  endwhile

  if current_indent < start_indent
    let start_indent = current_indent
  endif

  while 1
    let next_line = current_line
    while 1
      let next_line = Nextnonblank(next_line + step)
      let next_indent = indent(next_line)
      if next_line <= 0 || next_indent < 0 | return current_line | endif
      if !IgnoreLine(next_line) | break | endif
    endwhile

    if next_indent < start_indent
      return current_line
    elseif current_line + step != next_line
      if current_indent > 0 && next_indent == 0
        return next_line
      elseif start_indent == 0 && current_indent == 0
        return current_line
      endif
    endif

    let current_line = next_line
    let current_indent = next_indent
  endwhile
endfunction
