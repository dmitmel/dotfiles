" See also:
" <https://github.com/junegunn/fzf.vim/blob/master/autoload/fzf/vim.vim>
" <https://github.com/junegunn/fzf.vim/blob/master/plugin/fzf.vim>
" <https://github.com/junegunn/fzf/blob/master/plugin/fzf.vim>
"
" TODO: A command for feeding contents of qflist/loclist into FZF.

let g:dotfiles#fzf#manpage_search_actions = {
\ 'ctrl-t': 'tab',
\ 'ctrl-x': '',
\ 'ctrl-v': 'vertical',
\ }

function! dotfiles#fzf#manpage_search(fullscreen) abort
  call fzf#run(fzf#wrap('manpages', {
  \ 'source': 'man -k .',
  \ 'sink*': function('s:manpage_search_sink'),
  \ 'options': ['--prompt=:Man ', '--tiebreak=begin', '--multi',
  \   '--expect=' . join(keys(g:dotfiles#fzf#manpage_search_actions), ',')],
  \ }, a:fullscreen))
endfunction

function! s:manpage_search_sink(lines) abort
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
