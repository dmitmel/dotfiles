" A small plugin for reading and writing files with sudo in Neovim, which exists
" because the age-old trick of `:w !sudo tee %` does not work in Nvim (see the
" discussion here: <https://github.com/neovim/neovim/issues/12103>). It presents
" an "askpass" program to sudo to let it prompt the user for their password from
" within Neovim, and also makes sure that sudo remembers it, to avoid prompting
" for the password again and again for every damn operation.

if !has('nvim')
  echoerr expand('<sfile>').': this script is supposed to be used only in Neovim'
endif

let g:dotfiles#nvim#sudo#shell = get(g:, 'dotfiles#nvim#sudo#shell', 'sh')
let g:dotfiles#nvim#sudo#executable = get(g:, 'dotfiles#nvim#sudo#executable', 'sudo')
" -A: request sudo(1) to use an askpass helper program
let g:dotfiles#nvim#sudo#options = get(g:, 'dotfiles#nvim#sudo#options', '-A')

let s:dotfiles_dir = expand('<sfile>:h:h:h:h')
let s:askpass_helper_script = s:dotfiles_dir . '/nvim_askpass.sh'

" Now, you might be asking yourself: "What the fuck is this flaming pile of
" garbage?" Well, it has to do with keeping the user authenticated for executing
" commands with sudo.
"
" In order to remember the fact that the user has recently entered their
" credentials, sudo keeps track of the current TTY device, the PID of the
" process that invoked it and the so-called session ID of its own process (to be
" honest, I didn't even know that processes on UNIX have some session ID
" associated with them before - it's related to job control in the terminal, see
" credentials(7) for more information). However, for various reasons[1][2], on
" UNIX systems Neovim always creates a new session and process group for each
" subprocess it starts, whether it be spawned with the `:!` Ex command, or the
" functions |system()|, |systemlist()| or |jobstart()|. This means that when
" sudo is called through any method accessible from Vimscript, it will recognize
" those invocations as belonging to separate sessions, and therefore will ask
" the user to authenicate themselves every time a command needs to be invoked
" with sudo, every time you open or save a file from Vim.
"
" [1]: <https://github.com/neovim/neovim/issues/29475#issuecomment-2322091228>
" [2]: <https://github.com/neovim/neovim/commit/8d90171f8be6b92d7186ca84c42a0e07c2c71908>
"
" But you know what doesn't create new sessions for each new subprocess? Shells!
" So, to workaround this limitation of Neovim, I spawn a shell that will hang in
" the background and accept commands on its stdin, acting as a session leader
" for all sudo processes. Then, when the user reads or writes a file, I feed an
" appropriate command to this background shell instead of executing it directly
" with |system()|.
function! dotfiles#nvim#sudo#system(command) abort
  let job = s:start_background_shell()
  try
    " The background shell communicates with us by writing the results into temporary files.
    let pid_file = tempname()
    let exit_code_file = tempname()
    let done_file = tempname()

    " To be able to cancel the sudo command, we need to know its PID, to know
    " which process to send SIGINT to (sending SIGINT to the shell itself will
    " not work, the shell won't propagate this signal to its child processes).
    " The simplest way of doing that is to make a fork into a new shell process,
    " and record its PID before performing an `exec` to the actual command
    " (`exec` does not change the PID of the current process) - see
    " <https://serverfault.com/a/903631/950954>. Using just a subshell won't
    " work here because reading `$$` in a subshell will still return the PID of
    " the real shell process (as per the POSIX standard shells are not even
    " obligated to implement subshells by forking into a new process). There are
    " methods of getting the real PID even of subshells, such as `$BASHPID`, but
    " they are non-standard (<https://stackoverflow.com/a/21063837/12005228>).
    let payload = 'echo $$ > ' . shellescape(pid_file)
      \ . '; exec ' . fnameescape(g:dotfiles#nvim#sudo#executable)
      \ . ' ' . g:dotfiles#nvim#sudo#options . ' ' . a:command

    let cmd_str = shellescape(g:dotfiles#nvim#sudo#shell) . ' -c ' . shellescape(payload)

    " While creation of a file is an atomic operation (I think), writing data
    " into a file isn't, so to avoid a race condition when the `exit_code_file`
    " exists, but is empty from the viewpoint of Neovim (because the exit code
    " wasn't written to it yet), I use the creation of the `done_file` as a
    " point of absolute completion.
    let cmd_str .= '; echo $? > ' . shellescape(exit_code_file)
    let cmd_str .= '; : > ' . shellescape(done_file)  " this will create a new empty file

    let cmd_chunks = split("\n" . cmd_str . "\n", "\n", v:true)
    let res = exists('*chansend') ? chansend(job, cmd_chunks) : jobsend(job, cmd_chunks)

    let killed = v:false
    let IsDone = function('filereadable', [done_file])  " this works essentially like `.bind()` in JavaScript

    while v:true
      if exists('*wait')
        let status = wait(-1, IsDone, 10)
      else
        let status = 0
        try
          while !IsDone()
            sleep 10m  " asynchronous events will be processed while Nvim is sleeping
          endwhile
        catch /^Vim:Interrupt$/
          let status = -2
        endtry
      endif

      if status == 0  " IsDone() returned `true`
        break
      elseif status == -2  " wait() was interrupted
        if !killed
          try
            let pid = str2nr(readfile(pid_file, '', 1)[0])
          catch
            let pid = 0
          endtry
          if pid > 0 && !IsDone()
            let output = system('kill -INT ' . shellescape(pid))
            if v:shell_error
              echohl ErrorMsg
              unsilent echo output
              unsilent echo '[kill exited with code '.v:shell_error.']'
              echohl NONE
            endif
            let killed = v:true
          endif
        endif
      else
        throw 'wait() failed for an unknown reason with status ' . status
      endif
    endwhile

    let code = str2nr(readfile(exit_code_file, '', 1)[0])
    if code != 0 || killed
      echohl ErrorMsg
      unsilent echo '[sudo exited with code '.code.']'
      echohl NONE
      return v:false
    else
      return v:true
    endif
  finally
    silent! call delete(pid_file)
    silent! call delete(exit_code_file)
    silent! call delete(done_file)
  endtry
endfunction

function! s:start_background_shell() abort
  if !(exists('s:bg_shell_job') && jobwait([s:bg_shell_job], 0)[0] == -1)
    let opts = { 'stdin': 'pipe', 'on_stderr': function('s:job_output_handler') }
    let opts.on_stdout = opts.on_stderr

    let opts.env = { 'SUDO_ASKPASS': s:askpass_helper_script, 'NVIM_EXE': v:progpath }

    let undo_env = {}
    " The `env` parameter of |jobstart()| was added only in v0.5.0:
    " <https://github.com/neovim/neovim/commit/19b6237087ebcf45427ceb6943d23ce33b39567f>
    " It can be easily emulated, though.
    if !has('nvim-0.5.0')
      for [k, v] in items(opts.env)
        let undo_env[k] = exists('$'.k) ? eval('$'.k) : v:null
        execute 'let $'.k.' = v'
      endfor
    endif

    let s:bg_shell_job = jobstart([g:dotfiles#nvim#sudo#shell], opts)

    for [k, v] in items(undo_env)
      execute v is v:null ? 'unlet $'.k : 'let $'.k.' = v'
    endfor

    augroup dotfiles_nvim_sudo_job
      autocmd!
      autocmd VimLeavePre * call jobstop(s:bg_shell_job)
    augroup END
  endif

  return s:bg_shell_job
endfunction

function! s:job_output_handler(channel, data, event) abort dict
  let text = join(map(a:data, 'substitute(v:val, "\n", "<00>", "g")'), "\n")
  if !empty(text)
    exe 'echohl' (a:event ==# 'stderr' ? 'ErrorMsg' : 'NONE')
    unsilent echon text
    echohl NONE
  endif
endfunction

" This function will be called remotely from `../../../nvim_askpass.sh`.
function! dotfiles#nvim#sudo#askpass(prompt) abort
  call inputsave()
  try
    return inputsecret(a:prompt)
  finally
    " Clear the message area:
    unsilent echon "\n"
    call inputrestore()
    redraw
  endtry
endfunction

function! s:read(range, cmdarg, tempfile, real_path) abort
  let temp_file_buf_exists = bufexists(a:tempfile)

  let message = execute('noautocmd keepalt '.a:range.'read'.a:cmdarg.' '.fnameescape(a:tempfile))
  let message = message[0] ==# "\n" ? message[1:] : message

  if !temp_file_buf_exists && bufexists(a:tempfile)
    " Doing |:read| from another file will create an new unloaded buffer for that file.
    execute 'bwipeout ' . fnameescape(a:tempfile)
  endif

  let expected_prefix = '"' . fnamemodify(a:tempfile, ':~') . '" '
  if dotutils#starts_with(message, expected_prefix)
    let message = '"' . fnamemodify(a:real_path, ':~') . '" ' . message[len(expected_prefix):]
  endif

  return message
endfunction

function! s:write(range, cmdarg, tempfile, real_path) abort
  let temp_file_buf_exists = bufexists(a:tempfile)

  let message = execute('noautocmd keepalt '.a:range.'write'.a:cmdarg.' '.fnameescape(a:tempfile))
  let message = message[0] ==# "\n" ? message[1:] : message

  if !temp_file_buf_exists && bufexists(a:tempfile)
    " Doing |:write| to another file will create an new unloaded buffer for that file.
    execute 'bwipeout ' . fnameescape(a:tempfile)
  endif

  let expected_prefix = '"' . fnamemodify(a:tempfile, ':~') . '" '
  if dotutils#starts_with(message, expected_prefix)
    let info = message[len(expected_prefix):]
    " It will always say [New] because the saving is done into a new temporary
    " file every time.
    let info = substitute(info, dotutils#literal_regex(dotutils#gettext('[New]')), '', '')
    let info = info[0] ==# ' ' ? info[1:] : info
    let message = '"' . fnamemodify(a:real_path, ':~') . '" ' . info
  endif

  return message
endfunction

function! dotfiles#nvim#sudo#BufReadCmd(path) abort
  let tempfile = tempname()
  try
    if dotfiles#nvim#sudo#system('cat -- '.shellescape(a:path).' > '.shellescape(tempfile))
      silent %delete _
      let read_msg = s:read('', v:cmdarg . ' ++edit', tempfile, a:path)
      silent 1delete _

      setlocal nomodified

      if !filereadable(a:path)
        " This is a secret file, avoid leaking any information about it or its contents.
        setlocal noswapfile noundofile nomodeline
      elseif &l:undofile
        try
          silent rundo `=undofile(a:path)`
        catch /^Vim\%((\a\+)\)\=:E822:/
          " Cannot open undo file for reading
        endtry
      endif

      echomsg read_msg
    endif
  finally
    silent! call delete(tempfile)
  endtry
endfunction

function! dotfiles#nvim#sudo#BufWriteCmd(path) abort
  let tempfile = tempname()
  try
    let written_msg = s:write('', v:cmdarg, tempfile, a:path)

    if dotfiles#nvim#sudo#system('mkdir -p -- '.fnamemodify(a:path, ':h:S').' >/dev/null')
      if dotfiles#nvim#sudo#system('tee -- '.shellescape(a:path).' < '.shellescape(tempfile).' >/dev/null')
        if !filereadable(a:path)
          setlocal noswapfile noundofile nomodeline
        elseif &l:undofile
          silent wundo `=undofile(a:path)`
        endif

        " When |'cpoptions'| does not contain a `+`, |:write| should not reset
        " the |'modified'| flag of the buffer if it is written into a different
        " file. The idea to do this check was lifted from
        " <https://github.com/goerz/jupytext.nvim/blob/d7897ba4012c328f2a6bc955f1fe57578ebaceb1/lua/jupytext.lua#L100-L102>.
        " See also <https://github.com/neovim/neovim/blob/v0.11.6/runtime/plugin/shada.vim#L19-L21>.
        " NOTE: |nvim_buf_get_name()| returns a full, absolute path. We must
        " compare |<amatch>| against it, and not |<afile>|: |<afile>| can be
        " relative, while |<amatch>| is always expanded into an absolute path.
        if nvim_buf_get_name(+expand('<abuf>')) is# expand('<amatch>') || stridx(&cpoptions, '+') != -1
          setlocal nomodified
        endif

        echomsg written_msg
      endif
    endif
  finally
    silent! call delete(tempfile)
  endtry
endfunction

function! dotfiles#nvim#sudo#FileReadCmd(path) abort
  let tempfile = tempname()
  try
    if dotfiles#nvim#sudo#system('cat -- '.shellescape(a:path).' > '.shellescape(tempfile))
      let read_msg = s:read('', v:cmdarg, tempfile, a:path)
      echomsg read_msg
    endif
  finally
    silent! call delete(tempfile)
  endtry
endfunction

function! dotfiles#nvim#sudo#FileWriteCmd(path) abort
  let tempfile = tempname()
  try
    let written_msg = s:write("'[,']", v:cmdarg, tempfile, a:path)
    if dotfiles#nvim#sudo#system('tee -- '.shellescape(a:path).' < '.shellescape(tempfile).' >/dev/null')
      echomsg written_msg
    endif
  finally
    silent! call delete(tempfile)
  endtry
endfunction

function! dotfiles#nvim#sudo#FileAppendCmd(path) abort
  let tempfile = tempname()
  try
    " create an empty temporary file because appending can only be done to a file that exists
    call writefile([], tempfile, 'b')
    let appended_msg = s:write("'[,']", v:cmdarg . ' >>', tempfile, a:path)
    if dotfiles#nvim#sudo#system('tee -a -- '.shellescape(a:path).' < '.shellescape(tempfile).' >/dev/null')
      echomsg appended_msg
    endif
  finally
    silent! call delete(tempfile)
  endtry
endfunction
