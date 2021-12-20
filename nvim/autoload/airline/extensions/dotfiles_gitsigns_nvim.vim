" Based on <https://github.com/vim-airline/vim-airline/blob/bf5d785932b5bdedcb747311a8536931dd5241cc/autoload/airline/extensions/hunks.vim>

function! airline#extensions#dotfiles_gitsigns_nvim#init(ext) abort
  let s:non_zero_only = get(g:, 'airline#extensions#hunks#non_zero_only', 0)
  let s:hunk_symbols = get(g:, 'airline#extensions#hunks#hunk_symbols', ['+', '~', '-'])

  call airline#parts#define_function('hunks', 'airline#extensions#dotfiles_gitsigns_nvim#get_hunks')
endfunction

function! airline#extensions#dotfiles_gitsigns_nvim#get_hunks() abort
  if !get(w:, 'airline_active', 0) | return '' | endif
  let min_winwidth = get(airline#parts#get('hunks'), 'minwidth', 100)
  if airline#util#winwidth() < min_winwidth | return '' | endif

  let status = get(b:, 'gitsigns_status_dict', {})
  let hunks = [get(status, 'added', 0), get(status, 'changed', 0), get(status, 'removed', 0)]

  let str = ''
  if hunks !=# [0, 0, 0]
    for i in range(3)
      if s:non_zero_only && hunks[i] == 0 | continue | endif
      let str .= s:hunk_symbols[i] . hunks[i] . ' '
    endfor
  endif

  let has_branch_ext = index(airline#extensions#get_loaded_extensions(), 'branch') >= 0
  if !has_branch_ext && str[-1:] ==# ' '
    " branch extension not loaded, skip trailing whitespace
    let str = str[0:-2]
  endif
  return str
endfunction
