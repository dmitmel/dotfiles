" Based on <https://github.com/kana/vim-textobj-indent/blob/deb76867c302f933c8f21753806cbf2d8461b548/autoload/textobj/indent.vim>
" A motion for moving over enclosing indentation blocks. Primarily intended
" for reverse-engineering CrossCode.

function dotfiles#indent_motion#run(direction)
  let l:cursor_linenr = line(".")
  let l:max_linenr = line("$")

  let l:retry = 0
  while l:retry <# 2
    let l:retry += 1

    let l:base_linenr = l:cursor_linenr
    let l:base_indent = 0
    while 1 <=# l:base_linenr && l:base_linenr <=# l:max_linenr
      let l:base_indent = dotfiles#indent_motion#indent_level_of(l:base_linenr)
      if l:base_indent >=# 0
        break
      endif
      let l:base_linenr += a:direction
    endwhile

    let l:target_linenr = l:base_linenr

    let l:curr_linenr = l:base_linenr + a:direction
    let l:prev_indent = l:base_indent
    while 1 <=# l:curr_linenr && l:curr_linenr <=# l:max_linenr
      let l:indent = dotfiles#indent_motion#indent_level_of(l:curr_linenr)

      if l:indent >=# 0
        if l:indent <# l:base_indent
          break
        else
          let l:target_linenr = l:curr_linenr
        endif
      elseif l:base_indent ==# 0 && l:prev_indent ==# 0
        break
      endif

      let l:prev_indent = l:indent
      let l:curr_linenr += a:direction
    endwhile

    if l:target_linenr ==# l:cursor_linenr
      let l:cursor_linenr += a:direction
      if 1 <=# l:cursor_linenr && l:cursor_linenr <=# l:max_linenr
        continue
      endif
    endif

    break
  endwhile

  execute "normal! " . l:target_linenr . "G^"
endfunction

" <https://github.com/kana/vim-textobj-indent/blob/deb76867c302f933c8f21753806cbf2d8461b548/autoload/textobj/indent.vim#L120-L127>
function dotfiles#indent_motion#indent_level_of(linenr)  "{{{2
  if getline(a:linenr) ==# ""
    return -1
  endif
  return indent(a:linenr)
endfunction
