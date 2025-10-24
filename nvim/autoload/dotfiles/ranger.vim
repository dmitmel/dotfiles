" Superficial integration between Vim and the Ranger file manager[1] that opens
" ranger in a terminal emulator window (the idea was taken from the classic
" "oil and vinegar" article[2]). My implementation is based on the code from the
" ranger.vim plugin[3] by François Cabrol, distributed under the MIT license.
" [1]: <https://ranger.github.io/>
" [2}: <http://vimcasts.org/blog/2013/01/oil-and-vinegar-split-windows-and-project-drawer/>
" [3]: <https://github.com/francoiscabrol/ranger.vim/blob/91e82debdf566dfaf47df3aef0a5fd823cedf41c/plugin/ranger.vim>
"
function! dotfiles#ranger#run(ranger_args) abort
  let self = { 'edit_cmd': 'edit', 'choice_file': tempname() }

  let cmd = copy(get(g:, 'dotfiles#ranger#default_options', ['--cmd=' . 'set show_hidden true']))
  let literal_args = 0
  let found_choose_arg = 0

  for arg in a:ranger_args
    if !literal_args
      if arg ==# '--'
        let literal_args = 1
      elseif arg =~# '^+'
        let self.edit_cmd = arg[1:]
        continue
      elseif arg =~# '^--choose\%(files\?\|dir\)$'
        let arg .= '=' . self.choice_file
        let found_choose_arg = 1
      endif
    endif
    call add(cmd, arg)
  endfor

  if !found_choose_arg
    call insert(cmd, '--choosefiles=' . (self.choice_file))
  endif
  call insert(cmd, get(g:, 'dotfiles#ranger#command', 'ranger'))

  " The signatures for the exit callback are mostly compatible between Vim's
  " term_start() and Neovim's termopen(), taking the job ID and the exit code as
  " the parameters, with one small difference in that Neovim also adds a third
  " parameter which represents the event type, which for the exit callback is
  " always the string "exit". I make them fully compatible by means of varargs.
  function! self.on_exit(job_id, code, ...) abort
    if a:code != 0
      echohl ErrorMsg
      echomsg 'ranger exited with code '.a:code
      echohl NONE
      return
    endif

    if has_key(self, 'terminal_buf')
      " Must be done with a bang, older Neovim versions ask about closing the
      " terminal buffer even if the process in it is not running anymore.
      execute 'Bwipeout!' self.terminal_buf
    endif

    try
      let paths = readfile(self.choice_file)
    catch
      let paths = []
    endtry

    try
      call delete(self.choice_file)
    catch
      " Ignore the error if the file does not exist.
    endtry

    for path in paths
      try
        execute self.edit_cmd fnameescape(fnamemodify(path, ':~:.'))
      catch
        echohl ErrorMsg
        echomsg v:exception
        echohl NONE
      endtry
    endfor
  endfunction

  if has('nvim')
    enew
    let self.terminal_buf = bufnr('%')
    if has('nvim-0.11')
      let self.term = v:true
      call jobstart(cmd, self)
    else
      call termopen(cmd, self)
    endif
    setlocal nobuflisted
    startinsert
  elseif has('terminal')
    let self.terminal_buf = term_start(cmd, { 'curwin': 1, 'exit_cb': self.on_exit })
    call setbufvar(self.terminal_buf, '&buflisted', 0)
  else
    " Regular Vim executes commands in the TTY, so this will work just fine. The
    " only problem I experienced with this method of calling Ranger is that Vim
    " will fail to clear the screen after you close it, leaving the TUI in the
    " scrollback buffer of your terminal.
    silent execute '!' . join(map(cmd, 'shellescape(v:val, 1)'), ' ')
    call self.on_exit(-1, v:shell_error)
    redraw!
  endif
endfunction
