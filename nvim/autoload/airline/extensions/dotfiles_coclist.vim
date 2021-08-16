if !exists('g:did_coc_loaded') | finish | endif

function! airline#extensions#dotfiles_coclist#init(ext) abort
  let g:coc_user_config = get(g:, 'coc_user_config', {})
  let g:coc_user_config['list.statusLineSegments'] = v:null

  call a:ext.add_statusline_func('airline#extensions#dotfiles_coclist#apply')
  call a:ext.add_inactive_statusline_func('airline#extensions#dotfiles_coclist#apply')

  call airline#parts#define('dotfiles_coclist_mode', {
  \ 'function': 'airline#extensions#dotfiles_coclist#part_mode',
  \ 'accent': 'bold',
  \ })
  call airline#parts#define('dotfiles_coclist_args', {
  \ 'function': 'airline#extensions#dotfiles_coclist#part_args',
  \ })
  call airline#parts#define('dotfiles_coclist_name', {
  \ 'function': 'airline#extensions#dotfiles_coclist#part_name',
  \ })
  call airline#parts#define('dotfiles_coclist_cwd', {
  \ 'function': 'airline#extensions#dotfiles_coclist#part_cwd',
  \ })
  call airline#parts#define('dotfiles_coclist_loading', {
  \ 'function': 'airline#extensions#dotfiles_coclist#part_loading',
  \ })
  call airline#parts#define('dotfiles_coclist_total', {
  \ 'function': 'airline#extensions#dotfiles_coclist#part_total',
  \ })

  " Default airline section setup:
  " <https://github.com/vim-airline/vim-airline/blob/49cdcb7b3ea76ee19c737885c0ab19e64e564169/autoload/airline/init.vim#L209-L250>
  " Beware that whitespaces in function expansions can cause some weirdness:
  " <https://github.com/vim/vim/issues/3898>
  let s:section_a = airline#section#create_left(['dotfiles_coclist_mode'])
  let s:section_b = airline#section#create(['dotfiles_coclist_name'])
  let s:section_c = airline#section#create(['%<', 'dotfiles_coclist_args', ' ', 'dotfiles_coclist_loading'])
  let s:section_x = airline#section#create(['dotfiles_coclist_cwd'])
  let s:section_y = airline#section#create(['#%L/', 'dotfiles_coclist_total'])
  let s:section_z = airline#section#create(['%p%%', 'linenr', 'maxlinenr'])
endfunction

function! airline#extensions#dotfiles_coclist#statusline() abort
  let context = { 'winnr': winnr(), 'active': 1, 'bufnr': bufnr() }
  let builder = airline#builder#new(context)
  call airline#extensions#dotfiles_coclist#apply(builder, context)
  return builder.build()
endfunction

function! airline#extensions#dotfiles_coclist#apply(builder, context) abort
  if getbufvar(a:context.bufnr, '&filetype', '') !=# 'list' | return 0 | endif
  let list_status = getbufvar(a:context.bufnr, 'list_status', 0)
  if type(list_status) !=# v:t_dict | return 0 | endif

  " How b:list_status is populated:
  " <https://github.com/neoclide/coc.nvim/blob/0aa97ad1bbdcc2bb95cf7aabd7818643db1e269d/src/list/session.ts#L417-L433>
  " How the list buffer is created:
  " <https://github.com/neoclide/coc.nvim/blob/0aa97ad1bbdcc2bb95cf7aabd7818643db1e269d/autoload/coc/list.vim#L82-L100>
  " The default statusline:
  " <https://github.com/neoclide/coc.nvim/blob/0aa97ad1bbdcc2bb95cf7aabd7818643db1e269d/data/schema.json#L870-L884>
  " How airline generates its actual statuslines:
  " <https://github.com/vim-airline/vim-airline/blob/49cdcb7b3ea76ee19c737885c0ab19e64e564169/autoload/airline/extensions/default.vim>
  " <https://github.com/vim-airline/vim-airline/blob/49cdcb7b3ea76ee19c737885c0ab19e64e564169/autoload/airline/builder.vim>
  " <https://github.com/vim-airline/vim-airline/blob/49cdcb7b3ea76ee19c737885c0ab19e64e564169/autoload/airline/section.vim>

  let spc = g:airline_symbols.space
  if a:context.active || (!a:context.active && !g:airline_inactive_collapse)
    call a:builder.add_section('airline_a', s:get_section('a'))
    call a:builder.add_section('airline_b', s:get_section('b'))
  endif
  call a:builder.add_section('airline_c', s:get_section('c'))
  call a:builder.split()
  call a:builder.add_section('airline_x', s:get_section('x'))
  call a:builder.add_section('airline_y', s:get_section('y'))
  call a:builder.add_section('airline_z', s:get_section('z'))

  return 1
endfunction

" Copied from <https://github.com/vim-airline/vim-airline/blob/49cdcb7b3ea76ee19c737885c0ab19e64e564169/autoload/airline/extensions/default.vim#L7-L14>
let s:section_truncate_width = get(g:, 'airline#extensions#default#section_truncate_width', {
\ 'b': 79,
\ 'x': 60,
\ 'y': 88,
\ 'z': 45,
\ })

function! s:get_section(key) abort
  if has_key(s:section_truncate_width, a:key) && airline#util#winwidth() < s:section_truncate_width[a:key]
    return ''
  endif
  let spc = g:airline_symbols.space
  let text = s:section_{a:key}
  if empty(text) | return '' | endif
  return '%(' . spc . text . spc . '%)'
endfunction

" TODO: Is recoloring of the section A based on `b:list_status.mode` possible?
function! airline#extensions#dotfiles_coclist#part_mode() abort
  if get(w:, 'airline_active', 1)
    " <https://github.com/vim-airline/vim-airline/blob/49cdcb7b3ea76ee19c737885c0ab19e64e564169/autoload/airline/parts.vim#L55-L57>
    return airline#util#shorten(get(b:list_status, 'mode', ''), 79, 1)
  else
    return get(g:airline_mode_map, '__')
  endif
endfunction

function! airline#extensions#dotfiles_coclist#part_args() abort
  return get(b:list_status, 'args', '')
endfunction

function! airline#extensions#dotfiles_coclist#part_name() abort
  return get(b:list_status, 'name', '')
endfunction

function! airline#extensions#dotfiles_coclist#part_loading() abort
  return get(b:list_status, 'loading', '')
endfunction

function! airline#extensions#dotfiles_coclist#part_total() abort
  return get(b:list_status, 'total', '')
endfunction

function! airline#extensions#dotfiles_coclist#part_cwd() abort
  return pathshorten(fnamemodify(get(b:list_status, 'cwd', ''), ':~:.'))
endfunction
