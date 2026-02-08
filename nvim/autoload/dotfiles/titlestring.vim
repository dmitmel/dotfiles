function! dotfiles#titlestring#username() abort
  if has('nvim-0.4.0')
    try
      return luaeval('(vim.uv or vim.loop).os_get_passwd().username')
    catch
    endtry
  endif
  return has('win32') ? $USERNAME : $USER
endfunction

function! dotfiles#titlestring#hostname() abort
  return substitute(hostname(), '\C\.local$', '', '')
endfunction

function! dotfiles#titlestring#user_and_host() abort
  if !exists('s:user_and_host')
    if empty($SSH_TTY)
      let s:user_and_host = ''
    else
      let user = dotfiles#titlestring#username()
      let host = dotfiles#titlestring#hostname()
      let s:user_and_host = user . '@' . host . ': '
    endif
  endif
  return s:user_and_host
endfunction

function! dotfiles#titlestring#terminal() abort
  if has('nvim')
    let bufname = nvim_buf_get_name(0)
    if exists('b:term_title') && !empty(b:term_title) && b:term_title isnot# bufname
      return 'term: ' . b:term_title
    elseif has('nvim-0.6.0')
      let cmd = get(nvim_get_chan_info(&channel), 'argv', [''])
    else
      " Terminal buffers are named like this in Neovim: `term://{cwd}//{pid}:{command}`
      let cmd = split(substitute(bufname, '\C^term://.\{-}//\d\+:', '', ''))
    endif
  elseif exists('*term_gettitle')
    let title = term_gettitle('')
    if !empty(title)
      return 'term: ' . title
    else
      let cmd = job_info(term_getjob('')).cmd
    endif
  else
    let cmd = split(bufname('%'))
  endif
  return dotfiles#titlestring#user_and_host() . 'term: ' . fnamemodify(cmd[0], ':t')
endfunction

function! dotfiles#titlestring#get() abort
  if get(w:, 'snacks_layout', 0)
    let buf_title = "%{v:lua.dotfiles.snacks_picker_info('title')} picker"
  elseif &filetype ==# 'fzf' || exists('w:fzf_lua_win') || exists('w:fzf_lua_preview')
    let buf_title = "FZF%{exists('b:fzf') ? ' ' . get(b:fzf, 'name', '') : ''}"
  elseif &buftype ==# 'terminal'
    return '%{dotfiles#titlestring#terminal()} (%{v:progname})'
  elseif &buftype ==# 'help'
    " Special treatment of Help buffers: make sure to show the full path to the
    " help file (%F will expand to just the filename in Help buffers), and also
    " use %h to show the string [Help] at the end. %h is used instead of a
    " literal string because, hopefully, it will provide a translated string.
    let buf_title = '%{expand("%:~")} %h'
  else
    " %F is the file name as presented in `:ls`
    " %m is the Modified flag: [+] if &modified is true, [-] if &modifiable is
    " off (the latter I don't like)
    let buf_title = &modifiable ? '%F%m' : '%F'
  endif
  return '%{dotfiles#titlestring#user_and_host()}' . buf_title . ' (%{v:progname})'
endfunction
