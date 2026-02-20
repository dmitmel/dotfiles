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

function! s:read(range, cmdarg, tempfile, real_path) abort
  let message = execute('keepalt noautocmd '.a:range.'read'.a:cmdarg.' '.fnameescape(a:tempfile))
  let message = message[0] ==# "\n" ? message[1:] : message

  let expected_prefix = '"' . fnamemodify(a:tempfile, ':~') . '" '
  if dotutils#starts_with(message, expected_prefix)
    let message = '"' . fnamemodify(a:real_path, ':~') . '" ' . message[len(expected_prefix):]
  endif

  return message
endfunction

function! s:write(range, cmdarg, tempfile, real_path) abort
  let message = execute('keepalt noautocmd '.a:range.'write'.a:cmdarg.' '.fnameescape(a:tempfile))
  let message = message[0] ==# "\n" ? message[1:] : message

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

        setlocal nomodified

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
