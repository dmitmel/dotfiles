let s:CLOSE_CANCELED = 0
let s:CLOSE_NORMALLY = 1
let s:CLOSE_FORCIBLY = 2

function! s:error(str) abort
  let v:errmsg = a:str
  return 'echoerr v:errmsg'
endfunction

function! s:gettext(str) abort
  return exists('*gettext') ? gettext(a:str) : a:str
endfunction

" This is my own reimagining of the various plugins for closing buffers while
" keeping the window layout. This function takes a command to execute, either
" |:bdelete| or |:bwipeout|, with or without a bang at the end, and a pattern to
" find a buffer, and returns another command to execute for actually closing the
" buffer. The command is returned so that any errors which may appear are
" displayed at the callsite, without a stack trace, making it look nicer in the
" UI. |gettext()| is used everywhere so that the error messages can be
" translated appropriately.
function! dotfiles#bufclose#cmd(cmd, name) abort
  if empty(a:name)
    let buf_to_close = bufnr('%')
  elseif a:name =~# '^\d\+$'
    let buf_to_close = bufnr(str2nr(a:name, 10))
  else
    let buf_to_close = bufnr(a:name)
  endif
  if buf_to_close < 0
    return s:error(printf(s:gettext('E94: No matching buffer for %s'), a:name))
  endif

  let bang = ''
  if a:cmd !~# '!'  " check that the command does not contain a bang already
    let status = s:check_close_preconditions(buf_to_close)
    " `is` needs to be used instead of `==` here because `"not a number" == 0`.
    if status is s:CLOSE_CANCELED
      return ''
    elseif status is s:CLOSE_FORCIBLY
      let bang = '!'
    elseif status isnot s:CLOSE_NORMALLY
      return s:error(status)
    endif
  endif

  " Now, let's get down to business. To preserve the layout we want to find all
  " windows which display the given buffer, hide it in every single one of them
  " by switching to some other buffer, and then safely execute |:bd| or |:bw| on
  " the original buffer. Thing is, though, the |bufhidden| option may cause the
  " buffer to be deleted while we are hiding it, before we get the chance to do
  " the deletion ourselves. Therefore, change its value to `hide` such that the
  " buffer will stay loaded when it becomes completely hidden, and act out on
  " the previous setting of |bufhidden| afterwards.
  let prev_bufhidden = getbufvar(buf_to_close, '&bufhidden', '')
  call setbufvar(buf_to_close, '&bufhidden', 'hide')

  let original_winid = win_getid()

  for winid in win_findbuf(buf_to_close)
    if win_getid() != winid
      " |win_gotoid()| calls are guarded by an `if` because otherwise regular
      " Vim shows that we are in the PROMPT mode when this function finishes.
      call win_gotoid(winid)
    endif

    if buflisted(bufnr('#')) && bufnr('#') != buf_to_close
      buffer #
    else
      try
        bprevious
      catch /^Vim\%((\a\+)\)\=:E85:/  " E85: There is no listed buffer
      endtry
    endif

    if bufnr('%') == buf_to_close
      " Could not find another buffer to switch to? Create a new, empty one.
      " Beware, though, that if the buffer was already empty, `enew` will just
      " re-use it instead of creating a new one! See |buffer-reuse|.
      enew
      " An empty |buftype| is used instead of `nofile`, so that if something was
      " typed in the buffer, the user will be notified about the buffer being
      " modified when closing it. |nobuflisted| is needed so that `:bprevious`
      " above does not find this empty buffer.
      setlocal buftype= bufhidden=wipe nobuflisted noswapfile nomodeline
    endif
  endfor

  if win_getid() != original_winid
    call win_gotoid(original_winid)
  endif

  if !empty(win_findbuf(buf_to_close))
    " Exit without doing anything if the buffer is still displayed in some window.
    " This may happen, for instance, if |:enew| chose to reuse an empty buffer.
    return ''
  elseif prev_bufhidden ==# 'wipe'
    return 'bwipeout' . bang . ' ' . buf_to_close
  elseif prev_bufhidden ==# 'delete'
    return 'bdelete' . bang . ' ' . buf_to_close
  else
    return a:cmd . bang . ' ' . buf_to_close
  endif
endfunction

" Replicates the logic in <https://github.com/neovim/neovim/blob/v0.11.1/src/nvim/buffer.c#L1331-L1360>
function! s:check_close_preconditions(buf) abort
  let name = bufname(a:buf)

  if getbufvar(a:buf, '&buftype', '') ==# 'terminal'
    " <https://github.com/neovim/neovim/commit/55defa1a41baac65cd32dc499b330af9751d6c5b>
    if !dotutils#is_terminal_running(a:buf) && has('nvim-0.6.0')
      return s:CLOSE_NORMALLY
    endif
    if &confirm
      if has('nvim')
        " <https://github.com/neovim/neovim/blob/v0.11.1/src/nvim/ex_cmds2.c#L265-L279>
        let question = printf(s:gettext('Close "%s"?'), name)
        let answer = confirm(question, s:gettext("&Yes\n&No\n&Cancel"))
      else
        " <https://github.com/vim/vim/blob/v9.1.1401/src/terminal.c#L1809-L1826>
        let question = printf(s:gettext('Kill job in "%s"?'), name)
        let answer = confirm(question, s:gettext("&Yes\n&No"))
      endif
      return answer == 1 ? s:CLOSE_FORCIBLY : s:CLOSE_CANCELED
    else
      if has('nvim')
        return printf(s:gettext('E89: %s will be killed (add ! to override)'), name)
      else
        " <https://github.com/vim/vim/blob/v9.1.1401/src/buffer.c#L2084-L2094>
        return s:gettext('E948: Job still running (add ! to end the job)')
      endif
    endif
  endif

  if getbufvar(a:buf, '&modified', 0)
    if &confirm
      " <https://github.com/neovim/neovim/blob/v0.11.1/src/nvim/ex_docmd.c#L7570-L7578>
      let name = empty(name) ? s:gettext('Untitled') : name
      " <https://github.com/neovim/neovim/blob/v0.11.1/src/nvim/ex_cmds2.c#L208-L213>
      let question = printf(s:gettext('Save changes to "%s"?'), name)
      let answer = confirm(question, s:gettext("&Yes\n&No\n&Cancel"))
      if answer == 1  " Yes
        write
        return s:CLOSE_NORMALLY
      elseif answer == 2  " No
        return s:CLOSE_FORCIBLY
      else  " Cancel/Other
        return s:CLOSE_CANCELED
      endif
    else
      let numfmt = has('nvim') ? '%ld' : '%d'
      return printf('E89: No write since last change for buffer '.numfmt.' (add ! to override)', a:buf)
    endif
  endif

  return s:CLOSE_NORMALLY
endfunction
