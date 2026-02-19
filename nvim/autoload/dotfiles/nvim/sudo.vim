" Honestly, at this point this script is just a flaming pile of garbage...

if !has('nvim')
  echoerr expand('<sfile>').': this script is supposed to be used only within Neovim'
endif

let s:dotfiles_dir = expand('<sfile>:h:h:h:h')
let g:dotfiles#nvim#sudo#shell = get(g:, 'dotfiles#nvim#sudo#shell', 'sh')

function! s:job_output_handler(channel, data, event) abort dict
  let text = join(map(a:data, 'strtrans(v:val)'), "\n")
  if !empty(text)
    exe 'echohl' (a:event ==# 'stderr' ? 'ErrorMsg' : 'NONE')
    unsilent echon text
    echohl NONE
  endif
endfunction

function! s:start_background_shell() abort
  if !(exists('s:bg_shell_job') && jobwait([s:bg_shell_job], 0)[0] == -1)
    let opts = { 'stdin': 'pipe', 'on_stderr': function('s:job_output_handler') }
    let opts.on_stdout = opts.on_stderr

    " <https://github.com/neovim/neovim/commit/4dafd5341a04834e886428450a4720a4f961d1a4>
    let opts.env = { 'SUDO_ASKPASS': s:dotfiles_dir . '/nvim_askpass.sh', 'NVIM_EXE': v:progpath }

    let undo_env = {}
    if !has('nvim-0.5.0') " <https://github.com/neovim/neovim/commit/19b6237087ebcf45427ceb6943d23ce33b39567f>
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

function! dotfiles#nvim#sudo#system(command) abort
  let job = s:start_background_shell()
  try
    let pid_file = tempname()
    let exit_code_file = tempname()
    let done_file = tempname()

    let payload = 'echo $$ > ' . shellescape(pid_file) . '; exec sudo -A ' . a:command
    let cmd_str = shellescape(g:dotfiles#nvim#sudo#shell) . ' -c ' . shellescape(payload)
    let cmd_str .= '; echo $? > ' . shellescape(exit_code_file)
    let cmd_str .= '; : > ' . shellescape(done_file)
    if exists('##Signal') && !exists('#Signal#SIGUSR1')
      let cmd_str .= '; kill -USR1 ' . shellescape(getpid())
    endif
    let cmd_chunks = split("\n" . cmd_str . "\n", "\n", 1)
    let res = exists('*chansend') ? chansend(job, cmd_chunks) : jobsend(job, cmd_chunks)

    let killed = v:false
    let IsDone = function('filereadable', [done_file])

    while 1
      if exists('*wait')
        let status = wait(-1, IsDone, 20)
      else
        let status = 0
        try
          while !IsDone()
            sleep 20m
          endwhile
        catch /^Vim:Interrupt$/
          let status = -2
        endtry
      endif

      if status == 0
        break
      elseif status == -2
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

function! dotfiles#nvim#sudo#askpass(prompt) abort
  let out_of_memory = inputsave()
  if out_of_memory
    return ''
  endif
  try
    return inputsecret(a:prompt)
  finally
    unsilent echon "\n"
    call inputrestore()
    redraw
  endtry
endfunction

" TODO: swapfile

function! s:BufReadCmd() abort
  let file = expand('<afile>')
  exe 'silent doautocmd BufReadPre' fnameescape(file)

  " let prev_undoreload = &l:undoreload
  " let &l:undoreload = 0  " `:help clear-undo`
  try
    let tempfile = tempname()

    try
      if dotfiles#nvim#sudo#system('cat -- '.shellescape(file).' > '.shellescape(tempfile))
        silent %delete _

        let read_msg = execute('keepalt noautocmd read ++edit '.v:cmdarg.' '.fnameescape(tempfile))
        let read_msg = read_msg[0] ==# "\n" ? read_msg[1:] : read_msg

        let expected_prefix = '"' . fnamemodify(tempfile, ':~') . '" '
        if dotutils#starts_with(read_msg, expected_prefix)
          let read_msg = '"' . fnamemodify(file, ':~') . '" ' . read_msg[len(expected_prefix):]
        endif

        redraw
        echomsg read_msg

        silent 1delete _
        setlocal nomodified
      else
        return
      endif
    finally
      silent! call delete(tempfile)
    endtry

    if &l:undofile && filereadable(file)
      try
        silent rundo `=undofile(file)`
      catch /^Vim\%((\a\+)\)\=:E822:/
        " Cannot open undo file for reading
      endtry
    endif

  finally
    " let &l:undoreload = prev_undoreload
    exe 'silent doautocmd BufReadPost' fnameescape(file)
  endtry
endfunction

function! s:BufWriteCmd() abort
  let file = expand('<afile>')
  exe 'silent doautocmd BufWritePre' fnameescape(file)

  let tempfile = tempname()
  try
    let written_msg = execute('keepalt noautocmd write '.v:cmdarg.' '.fnameescape(tempfile))
    let written_msg = written_msg[0] ==# "\n" ? written_msg[1:] : written_msg

    let expected_prefix = '"' . fnamemodify(tempfile, ':~') . '" '
    if dotutils#starts_with(written_msg, expected_prefix)
      let info = written_msg[len(expected_prefix):]
      " It will always say [New] because the saving is done into a new temporary
      " file every time.
      let info = substitute(info, dotutils#literal_regex(dotutils#gettext('[New]')), '', '')
      let info = info[0] ==# ' ' ? info[1:] : info
      let written_msg = '"' . fnamemodify(file, ':~') . '" ' . info
    endif

    if dotfiles#nvim#sudo#system('mkdir -p -- '.fnamemodify(file, ':h:S').' >/dev/null')
      if dotfiles#nvim#sudo#system('tee -- '.shellescape(file).' < '.shellescape(tempfile).' >/dev/null')
        if &l:undofile && filereadable(file)
          silent wundo `=undofile(file)`
        endif

        setlocal nomodified

        redraw
        echomsg written_msg
      endif
    endif

  finally
    silent! call delete(tempfile)
    exe 'silent doautocmd BufWritePost' fnameescape(file)
  endtry
endfunction

function! s:set_autocommands(buf, enable) abort
  let buf = bufnr(a:buf)
  if buf <= 0
    throw 'buffer not found: ' . a:buf
  endif

  augroup dotfiles_nvim_sudo
    exe 'autocmd! * <buffer='.buf.'>'
    if a:enable
      exe 'autocmd BufDelete,BufWipeout <buffer='.buf.'>'
            \ 'silent! autocmd! dotfiles_nvim_sudo * <buffer='.buf.'>'
      exe 'autocmd BufReadCmd  <buffer='.buf.'> unsilent call s:BufReadCmd()'
      exe 'autocmd BufWriteCmd <buffer='.buf.'> unsilent call s:BufWriteCmd()'
    endif
  augroup END
endfunction

function! dotfiles#nvim#sudo#enable(buf) abort
  call s:set_autocommands(a:buf, 1)
endfunction

function! dotfiles#nvim#sudo#disable(buf) abort
  call s:set_autocommands(a:buf, 0)
endfunction

function! dotfiles#nvim#sudo#is_enabled(buf) abort
  let buf = bufnr(a:buf)
  return buf > 0 && exists('#dotfiles_nvim_sudo#BufWriteCmd#<buffer='.buf.'>')
endfunction

function! dotfiles#nvim#sudo#toggle(buf) abort
  call s:set_autocommands(a:buf, !dotfiles#nvim#sudo#is_enabled(a:buf))
endfunction
