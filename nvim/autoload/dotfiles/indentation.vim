function! dotfiles#indentation#unindent(first_line, last_line, base_indent) abort
  let nonblank_linenrs = filter(range(a:first_line, a:last_line), '!empty(getline(v:val))')
  let min_indent = min(map(copy(nonblank_linenrs), 'indent(v:val)'))
  let delta = min_indent - a:base_indent
  for linenr in nonblank_linenrs
    execute linenr.'left' (indent(linenr) - delta)
  endfor
endfunction

function! dotfiles#indentation#run_indent_motion_next() abort
  let linenr = s:run_indent_motion(1)
  execute 'normal! ' . linenr . 'G^'
endfunction

function! dotfiles#indentation#run_indent_motion_prev() abort
  let linenr = s:run_indent_motion(-1)
  execute 'normal! ' . linenr . 'G^'
endfunction

" Based on <https://github.com/kana/vim-textobj-indent/blob/deb76867c302f933c8f21753806cbf2d8461b548/autoload/textobj/indent.vim>
" A motion for moving over enclosing indentation blocks. Primarily intended
" for reverse-engineering CrossCode.
function! s:run_indent_motion(direction) abort
  let Nextnonblank = a:direction > 0 ? function('nextnonblank') : function('prevnonblank')
  let cursor_linenr = line('.')
  let max_linenr = line('$')

  let base_linenr = Nextnonblank(cursor_linenr)
  let base_indent = indent(base_linenr)
  if base_linenr <= 0 || base_indent < 0 | return cursor_linenr | endif

  let curr_linenr = Nextnonblank(base_linenr + a:direction)
  let curr_indent = indent(curr_linenr)
  if curr_linenr <= 0 || curr_indent < 0 | return base_linenr | endif

  if curr_indent < base_indent
    let base_indent = curr_indent
  endif

  while 1
    let next_linenr = Nextnonblank(curr_linenr + a:direction)
    let next_indent = indent(next_linenr)
    if next_linenr <= 0 || next_indent < 0 | return curr_linenr | endif

    if next_indent < base_indent
      return curr_linenr
    elseif curr_linenr + a:direction != next_linenr
      if curr_indent > 0 && next_indent == 0
        return next_linenr
      elseif base_indent == 0 && curr_indent == 0
        return curr_linenr
      endif
    endif

    let curr_linenr = next_linenr
    let curr_indent = next_indent
  endwhile
endfunction
