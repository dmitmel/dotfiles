" Based on <https://github.com/kana/vim-textobj-indent/blob/deb76867c302f933c8f21753806cbf2d8461b548/autoload/textobj/indent.vim>
" A motion for moving over enclosing indentation blocks. Primarily intended
" for reverse-engineering CrossCode.

function! dotfiles#indent_motion#run(direction) abort
  let cursor_linenr = line('.')
  let max_linenr = line('$')

  let retry = 0
  while retry <# 2
    let retry += 1

    let base_linenr = cursor_linenr
    let base_indent = 0
    while 1 <=# base_linenr && base_linenr <=# max_linenr
      let base_indent = dotfiles#indent_motion#indent_level_of(base_linenr)
      if base_indent >=# 0
        break
      endif
      let base_linenr += a:direction
    endwhile

    let target_linenr = base_linenr

    let curr_linenr = base_linenr + a:direction
    let prev_indent = base_indent
    while 1 <=# curr_linenr && curr_linenr <=# max_linenr
      let indent = dotfiles#indent_motion#indent_level_of(curr_linenr)

      if indent >=# 0
        if indent <# base_indent
          break
        else
          let target_linenr = curr_linenr
        endif
      elseif base_indent ==# 0 && prev_indent ==# 0
        break
      endif

      let prev_indent = indent
      let curr_linenr += a:direction
    endwhile

    if target_linenr ==# cursor_linenr
      let cursor_linenr += a:direction
      if 1 <=# cursor_linenr && cursor_linenr <=# max_linenr
        continue
      endif
    endif

    break
  endwhile

  execute 'normal! ' . target_linenr . 'G^'
endfunction

" <https://github.com/kana/vim-textobj-indent/blob/deb76867c302f933c8f21753806cbf2d8461b548/autoload/textobj/indent.vim#L120-L127>
function! dotfiles#indent_motion#indent_level_of(linenr) abort
  if empty(getline(a:linenr))
    return -1
  endif
  return indent(a:linenr)
endfunction
