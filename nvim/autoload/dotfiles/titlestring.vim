function! dotfiles#titlestring#user_and_host() abort
  if !exists('s:user_and_host')
    let s:user_and_host = $USER . '@' . substitute(hostname(), '\C\.local$', '', '')
  endif
  return s:user_and_host
endfunction

function! dotfiles#titlestring#terminal() abort
  let buf_name = bufname('%')
  let term_title = exists('b:term_title') ? b:term_title : exists('*term_gettitle') ? term_gettitle('%') : ''
  if !empty(term_title) && term_title !=# buf_name
    return term_title
  endif
  " Terminal buffers names:
  " - in Neovim -- `term://{cwd}//{pid}:{cmd}`
  " - in Vim -- `!${cmd}`.
  let cmd = substitute(buf_name, '\C^!\|^term://.\{-}//\d\+:', '', '')
  return dotfiles#titlestring#user_and_host().': '.cmd.' [Terminal]'
endfunction

function! dotfiles#titlestring#get() abort
  if &filetype ==# 'fzf'
    let str = "FZF %{exists('b:fzf') ? get(b:fzf, 'name', '') : ''}"
  elseif &buftype ==# 'terminal'
    return '%{dotfiles#titlestring#terminal()} (%{v:progname})'
  elseif &buftype ==# 'help'
    " Special treatment of Help buffers: make sure to show the full path to
    " the help file (%F will expand to the filename in Help buffers), and also
    " use %h to show the string [Help] in the end. %h is used instead of a
    " literal string because, hopefully, it will provide a translated string.
    let str = '%{expand("%:~")} %h'
  else
    " %F is the file name as presented in `:ls`
    " %m is the Modified flag: [+] if &modified, [-] if &modifiable is off.
    let str = '%F%m'
  endif
  return '%{dotfiles#titlestring#user_and_host()}: ' . str . ' (%{v:progname})'
endfunction
