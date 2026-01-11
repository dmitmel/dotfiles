" A superficial integration between (Neo)Vim and the Ranger-like file managers[1][2]
" that opens ranger in a terminal in the current window (this idea was taken
" from the classic "Oil and vinegar" article[3]). My implementation was
" initially inspired by code of the ranger.vim plugin[4] by François Cabrol,
" which is distributed under the MIT license.
" [1]: <https://ranger.github.io/>
" [2]: <https://github.com/gokcehan/lf>
" [3]: <http://vimcasts.org/blog/2013/01/oil-and-vinegar-split-windows-and-project-drawer/>
" [4]: <https://github.com/francoiscabrol/ranger.vim/blob/91e82debdf566dfaf47df3aef0a5fd823cedf41c/plugin/ranger.vim>

function! dotfiles#ranger#run_ranger(opts) abort
  let self = {}

  let cmd = get(g:, 'dotfiles#ranger#ranger_command', ['ranger', '--cmd=set show_hidden true'])
  let cmd = type(cmd) is v:t_list ? copy(cmd) : [cmd]

  if has_key(a:opts, 'open_with')
    let self.open_with = a:opts.open_with
    let self.choice_file = tempname()
    call add(cmd, '--choose' . get(a:opts, 'choose', 'files') . '=' . self.choice_file)
  endif

  if has_key(a:opts, 'extra_args')
    call extend(cmd, a:opts.extra_args)
  endif

  let path = empty(get(a:opts, 'select', '')) ? expand('%:p') : a:opts.select
  if !empty(path)
    call add(cmd, '--selectfile=' . path)
  endif

  call dotfiles#ranger#run_in_terminal(cmd, function('s:ranger_done', [], self))
endfunction

function! s:ranger_done(exit_code) dict abort
  if a:exit_code isnot 0
    echoerr 'ranger exited with code '.a:exit_code
  else
    call s:open_all(self.open_with, s:consume_file(self.choice_file))
  endif
endfunction

function! dotfiles#ranger#run_lf(opts) abort
  let self = {}

  " NOTE: starting `lf` with `-single` prevents built-in commands like `:maps` from working
  let cmd = get(g:, 'dotfiles#ranger#lf_command', 'lf')
  let cmd = type(cmd) is v:t_list ? copy(cmd) : [cmd]

  if has_key(a:opts, 'open_with')
    let self.open_with = a:opts.open_with
    let self.selection_path = tempname()
    call add(cmd, '-selection-path=' . self.selection_path)
  endif

  if has_key(a:opts, 'open_chosen_dir_with')
    let self.open_chosen_dir_with = a:opts.open_chosen_dir_with
    let self.last_dir_path = tempname()
    call add(cmd, '-last-dir-path=' . self.last_dir_path)
  endif

  if has_key(a:opts, 'extra_args')
    call extend(cmd, a:opts.extra_args)
  endif

  let path = empty(get(a:opts, 'select', '')) ? expand('%:p') : a:opts.select
  if !empty(path)
    call add(cmd, '--')
    call add(cmd, path)
  endif

  call dotfiles#ranger#run_in_terminal(cmd, function('s:lf_done', [], self))
endfunction

function! s:lf_done(exit_code) dict abort
  if a:exit_code isnot 0
    echoerr 'lf exited with code '.a:exit_code
    return
  endif

  let selected_files = s:consume_file(get(self, 'selection_path'), 'b')
  let last_dir = join(s:consume_file(get(self, 'last_dir_path'), 'b'), "\n")

  call s:open_all(get(self, 'open_with'), selected_files)
  if !empty(last_dir)
    call s:open_all(get(self, 'open_chosen_dir_with'), [last_dir])
  endif
endfunction

" Reads the contents of a file and immediately deletes it, ignoring any I/O errors.
function! s:consume_file(path, ...) abort
  if empty(a:path)
    return []
  endif
  try
    return call('readfile', [a:path] + a:000)
  catch
    return []
  finally
    silent! call delete(a:path)
  endtry
endfunction

" See also: <https://github.com/junegunn/fzf/blob/2ab923f3ae04d5e915e5ff4a9cd3bd515bfd1ea5/plugin/fzf.vim#L307-L357>
function! s:open_all(cmd, paths) abort
  if empty(a:cmd)
    return
  elseif type(a:cmd) is v:t_func
    return a:cmd(a:paths)
  endif

  let cmd_is_edit = split(a:cmd)[-1] =~# '^e\%[dit]'
  " Turn all paths into absolute paths before opening any of them because the
  " current directory might get changed by |'autochdir'| in the process and
  " change the meaning of relative paths.
  for path in map(filter(copy(a:paths), '!empty(v:val)'), 'fnamemodify(v:val, ":p")')
    " Don't re-edit the file in the current buffer because that causes a |reload|.
    " See also: <https://github.com/junegunn/fzf/pull/2096>
    if cmd_is_edit && path ==# expand('%:p') | continue | endif
    " Relativize the current path before executing the command to open it to
    " keep the name of the created buffer nice and short.
    let path = fnamemodify(path, ':.')
    " The relativization step may return an empty string if the given path is
    " equal to the current directory plus a slash `/`, which is essentially the
    " same as `.`, even if symlinks are involved, apparently:
    " <https://github.com/nodejs/node/issues/45617#issuecomment-1326819514>.
    if empty(path) | let path = '.' | endif
    " Escape a leading tilde character so that it gets interpreted as a regular
    " path component. |fnameescape()| doesn't escape it for some reason.
    if path[0] ==# '~' | let path = './' . path | endif

    try
      execute a:cmd fnameescape(path)
      let exception_caught = 0
    catch
      " Doing |:echoerr| within the |:catch| block is interpreted as throwing an
      " exception, and therefore ends the execution of the current function.
      " However, I want to continue opening all requested paths even if one
      " fails and display errors from all of them, so I need to back up the
      " information about the caught exception to display it later.
      let exception = v:exception
      let throwpoint = v:throwpoint
      let exception_caught = 1
    endtry

    if exception_caught
      " Even though the output of |:echoerr| is a bit ugly, it is the only
      " reliable way of displaying an error message and ensuring that it is seen
      " and acknowledged by the user. Unfortunately, if |:echomsg| is used here,
      " it does not stop Vimscript execution and show a "hit enter" prompt, but
      " instead the message gets silently written to the message history and is
      " not even shown under the status line (because switching to another
      " buffer clears the message area). |:echoerr| will not show the throwpoint
      " of the original exception, so we have to format an exception error
      " message appropriately ourselves.
      " <https://github.com/neovim/neovim/blob/v0.11.5/src/nvim/message.c#L596>
      echoerr printf(dotutils#gettext('Error detected while processing %s:'), throwpoint)
            \ . "\n" . exception
    endif
  endfor
endfunction

function! dotfiles#ranger#run_in_terminal(cmd, callback) abort
  let self = { 'callback': a:callback }
  let self.on_exit = function('s:terminal_job_exited', [], self)

  if has('nvim')
    enew
    setlocal nobuflisted
    let self.terminal_buf = bufnr('%')
    if has('nvim-0.11')
      call jobstart(a:cmd, { 'term': v:true, 'on_exit': self.on_exit })
    else
      call termopen(a:cmd, { 'on_exit': self.on_exit })
    endif
    startinsert
    return self.terminal_buf
  endif

  if has('terminal')
    let self.terminal_buf = term_start(a:cmd, { 'curwin': 1, 'exit_cb': self.on_exit })
    call setbufvar(self.terminal_buf, '&buflisted', 0)
    return self.terminal_buf
  endif

  " Regular Vim executes commands in the TTY, so spawning Ranger with `:!` will
  " work just fine. `:silent` is needed to disable the "hit enter" prompt. The
  " only problem I encountered with this method is that Vim may fail to clear
  " the screen after you exit it after using Ranger like this once, leaving the
  " TUI of the editor in the scrollback of your terminal.
  execute 'silent !' . join(map(copy(a:cmd), 'shellescape(v:val, 1)'), ' ')
  redraw!   " re-paint the TUI
  call a:callback(v:shell_error)
  return 0  " no new buffer was created
endfunction

" The signatures for the job exit callback are mostly compatible between Vim's
" term_start() and Neovim's termopen(), taking the job ID and the exit code as
" the parameters, with one small difference in that Neovim also adds a third
" parameter which represents the event type, which for the exit callback is
" always the string "exit". I make them fully compatible by means of varargs.
function! s:terminal_job_exited(job_id, code, ...) dict abort
  execute 'Bwipeout!' self.terminal_buf
  call self.callback(a:code)
endfunction
