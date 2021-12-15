" See also:
" <https://github.com/junegunn/fzf.vim/blob/master/autoload/fzf/vim.vim>
" <https://github.com/junegunn/fzf.vim/blob/master/plugin/fzf.vim>
" <https://github.com/junegunn/fzf/blob/master/plugin/fzf.vim>
"
" TODO: A command for feeding contents of qflist/loclist into FZF.

" Well, ideally this should somehow read terminfo to handle non-standard
" terminal escape sequences, but what do you want from poor Vimscript :harold:.
" See: <https://en.wikipedia.org/wiki/ANSI_escape_code#Description>
" See: <https://github.com/junegunn/fzf.vim/blob/d6aa21476b2854694e6aa7b0941b8992a906c5ec/autoload/fzf/vim.vim#L227-L256>
function! dotfiles#fzf#hlgroup_to_ansi(group) abort
  let id = synIDtrans(hlID(a:group))
  if id < 0
    return
  endif

  " NOTE: the `mode` argument to `synIDattr` can be omitted, then the mode is
  " determined automatically.
  " let ui_mode = has('termguicolors') && &termguicolors ? 'gui' : 'cterm'

  " "Select Graphic Rendition" commands
  let sgr = []

  " `fg#` and `bg#` attributes differ from `fg` and `bg` in that they return
  " resolved RGB values of colors if a color was specified by its name.
  let fg = synIDattr(id, 'fg#')
  let bg = synIDattr(id, 'bg#')
  " let sp = synIDattr(id, 'sp#')
  if !empty(fg)
    call add(sgr, dotfiles#fzf#_vim_color_str_to_ansi(fg, '3'))
  endif
  if !empty(bg)
    call add(sgr, dotfiles#fzf#_vim_color_str_to_ansi(bg, '4'))
  endif
  " Sets the underline color, but is non-standard.
  " if !empty(sp)
  "   call add(sgr, '58;' . dotfiles#fzf#vim_color_str_to_ansi(fg, ''))
  " endif

  if !empty(synIDattr(id, 'bold'))
    call add(sgr, '1')
  endif
  if !empty(synIDattr(id, 'italic'))
    call add(sgr, '3')
  endif
  if !empty(synIDattr(id, 'underlined')) || !empty(synIDattr(id, 'undercurl'))
    call add(sgr, '4')
  endif
  if !empty(synIDattr(id, 'reverse')) || !empty(synIDattr(id, 'inverse')) || !empty(synIDattr(id, 'standout'))
    call add(sgr, '7')
  endif
  if !empty(synIDattr(id, 'strikethrough'))
    call add(sgr, '9')
  endif

  return "\x1b[" . join(sgr, ';') . 'm'
endfunction

function! dotfiles#fzf#_vim_color_str_to_ansi(color, cmd_start) abort
  if a:color =~# '^#\x\{6}$'
    let str = '2;'.str2nr(a:color[1:2],16).';'.str2nr(a:color[3:4],16).';'.str2nr(a:color[5:6],16)
    return !empty(a:cmd_start) ? a:cmd_start.'8;'.str : str
  elseif a:color ==# 'fg' || a:color ==# 'bg'
    throw 'TODO, ' . a:color . ' color references are not supported'
  elseif a:color =~# '^\d'
    " Well, don't ask me about the modulo. This is how it works in Vim.
    let idx = str2nr(a:color, 10) % 0x100
    if !empty(a:cmd_start) && idx < 0x8
      return a:cmd_start . idx
    els
      return a:cmd_start.'8;5;'.idx
    endif
  else
    throw 'Invalid color: ' . string(a:color)
  endif
endfunction

function! dotfiles#fzf#hlgroup_ansi_wrap(group, text) abort
  let cmd = dotfiles#fzf#hlgroup_to_ansi(a:group)
  if !empty(cmd)
    return cmd . a:text . "\x1b[m"
  else
    return a:text
  endif
endfunction

function! s:ansi(group, text) abort
  return dotfiles#fzf#hlgroup_ansi_wrap(a:group, a:text)
endfunction

let g:dotfiles#fzf#manpage_search_actions = {
\ 'ctrl-t': 'tab',
\ 'ctrl-x': '',
\ 'ctrl-v': 'vertical',
\ }

function! dotfiles#fzf#manpage_search(fullscreen) abort
  call s:delete_manpages_script()
  let s:manpages_script = tempname()
  call writefile(['/^\s*(\S+)\s*\((\w+)\)\s*-\s*(.+)$/; printf(qq('. s:ansi('Label', '%-50s')
  \ .'\t%s\n), sprintf("%s(%s)", $1, $2), $3)'], s:manpages_script)
  let results = fzf#run(fzf#wrap('manpages', {
  \ 'source': 'man -k . | perl -n ' . fzf#shellescape(s:manpages_script),
  \ 'sink*': function('s:manpage_search_sink'),
  \ 'options': ['--ansi', '--prompt=:Man ', '--tiebreak=begin', '--multi',
  \   '--expect=' . join(keys(g:dotfiles#fzf#manpage_search_actions), ',')],
  \ }, a:fullscreen))
  return results
endfunction

function! s:delete_manpages_script() abort
  if exists('s:manpages_script')
    silent! call delete(s:manpages_script)
    unlet! s:manpages_script
  endif
endfunction

function! s:manpage_search_sink(lines) abort
  call s:delete_manpages_script()
  if len(a:lines) < 2 | return | endif
  let pressed_key = a:lines[0]
  let modifiers = get(g:dotfiles#fzf#manpage_search_actions, pressed_key, '')
  for choice in a:lines[1:]
    let groups = matchlist(choice, '\v^\s*(\S+)\s*\((\w+)\)')
    if !empty(groups)
      let [name, section] = groups[1:2]
      " <https://github.com/neovim/neovim/blob/master/runtime/plugin/man.vim#L8-L10>
      " I would rather not deal with escaping the man page name, even though this
      " requires calling a private function.
      call man#open_page(-1, modifiers, name.'('.section.')')
    endif
  endfor
endfunction
