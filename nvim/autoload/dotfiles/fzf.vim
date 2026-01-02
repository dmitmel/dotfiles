" See also:
" <https://github.com/junegunn/fzf.vim/blob/master/autoload/fzf/vim.vim>
" <https://github.com/junegunn/fzf.vim/blob/master/plugin/fzf.vim>
" <https://github.com/junegunn/fzf/blob/master/plugin/fzf.vim>
"
" Well, ideally this should somehow read terminfo to handle non-standard
" terminal escape sequences, but what do you want from poor Vimscript :harold:.
" See: <https://en.wikipedia.org/wiki/ANSI_escape_code#Description>
" See: <https://github.com/junegunn/fzf.vim/blob/d6aa21476b2854694e6aa7b0941b8992a906c5ec/autoload/fzf/vim.vim#L227-L256>
function! dotfiles#fzf#hlgroup_to_ansi(group) abort
  let id = synIDtrans(hlID(a:group))
  if id < 0
    return ''
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
    call add(sgr, s:vim_color_to_ansi(fg,'3'))
  endif
  if !empty(bg)
    call add(sgr, s:vim_color_to_ansi(bg,'4'))
  endif
  " Sets the underline color, but is non-standard.
  " if !empty(sp)
  "   call add(sgr, '58;' . s:vim_color_to_ansi(fg, ''))
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

  return "\e[" . join(sgr, ';') . 'm'
endfunction

function! s:vim_color_to_ansi(color, cmd_start) abort
  if a:color =~# '^#\x\{6}$'
    let str = '2;'.str2nr(a:color[1:2],16).';'.str2nr(a:color[3:4],16).';'.str2nr(a:color[5:6],16)
    return !empty(a:cmd_start) ? a:cmd_start.'8;'.str : str
  elseif a:color =~# '^\d'
    " Well, don't ask me about the modulo. This is how it works in Vim.
    let idx = str2nr(a:color, 10) % 0x100
    if !empty(a:cmd_start) && idx < 0x8
      return a:cmd_start . idx
    els
      return a:cmd_start.'8;5;'.idx
    endif
  elseif a:color ==# 'fg'
    let fg = synIDattr(synIDtrans(hlID('Normal')), 'fg#')
    return s:vim_color_to_ansi(fg, a:cmd_start)
  elseif a:color ==# 'bg'
    let bg = synIDattr(synIDtrans(hlID('Normal')), 'bg#')
    return s:vim_color_to_ansi(bg, a:cmd_start)
  else
    throw 'Invalid color: ' . string(a:color)
  endif
endfunction

function! dotfiles#fzf#hlgroup_to_fzf_color(group, group_attr) abort
  if a:group_attr !=? 'fg' && a:group_attr !=? 'bg'
    throw 'Only fg and bg are allowed'
  endif

  let id = synIDtrans(hlID(a:group))
  if id < 0
    return ''
  endif

  let attrs = []

  let color = synIDattr(id, a:group_attr . '#')
  if !empty(color)
    if color =~# '^#\x\{6}$'
      call add(attrs, color)
    elseif color =~# '^\d'
      call add(attrs, str2nr(color, 10) % 0x100)
    elseif color ==# 'fg'
      return dotfiles#fzf#hlgroup_to_fzf_color('Normal', 'fg')
    elseif color ==# 'bg'
      return dotfiles#fzf#hlgroup_to_fzf_color('Normal', 'bg')
    else
      throw 'Invalid color: ' . string(color)
    endif
  else
    call add(attrs, '-1')
  endif

  if a:group_attr ==# 'fg'
    if !empty(synIDattr(id, 'bold'))
      call add(attrs, 'bold')
    endif
    if !empty(synIDattr(id, 'italic'))
      call add(attrs, 'italic')
    endif
    if !empty(synIDattr(id, 'underlined')) || !empty(synIDattr(id, 'undercurl'))
      call add(attrs, 'underline')
    endif
    if !empty(synIDattr(id, 'reverse')) || !empty(synIDattr(id, 'inverse')) || !empty(synIDattr(id, 'standout'))
      call add(attrs, 'reverse')
    endif
  endif

  return join(attrs, ':')
endfunction

let g:dotfiles#fzf#manpage_search_actions = {
\ 'ctrl-t': 'tab',
\ 'ctrl-x': '',
\ 'ctrl-v': 'vertical',
\ }

let s:fancy_man_pager = expand('<sfile>:p:h:h:h:h') . '/scripts/fancy-man-pager'

function! dotfiles#fzf#manpage_search(fullscreen) abort
  let perl_script =
  \ '/^\s*(\S+)\s*\((\w+)\)\s*-\s*(.+)$/; printf(qq(%s\t%s\t%-45s %s\n), $2, $1, sprintf("%s (%s)", $1, $2), $3)'

  let dict = {
  \ 'source': 'man -k . | perl -ne ' . fzf#shellescape(perl_script),
  \ 'sink*': function('s:manpage_search_sink'),
  \ 'options': ['--ansi', '--prompt=:Man ', '--tiebreak=begin,chunk', '--multi', '--with-nth=3..',
  \   '--preview', 'MANWIDTH=$FZF_PREVIEW_COLUMNS ' . s:fancy_man_pager . ' {1} {2}',
  \   '--expect=' . join(keys(g:dotfiles#fzf#manpage_search_actions), ',')],
  \ 'placeholder': '',
  \ }

  let dict = fzf#vim#with_preview(dict)
  call add(dict.options, '--preview-window=80')

  return fzf#run(fzf#wrap('manpages', dict, a:fullscreen))
endfunction

function! s:manpage_search_sink(lines) abort
  if len(a:lines) < 2 | return | endif
  let pressed_key = a:lines[0]
  let modifiers = get(g:dotfiles#fzf#manpage_search_actions, pressed_key, '')
  for choice in a:lines[1:]
    let [section, page; remaining] = split(choice)
    execute modifiers 'Man' escape(section, '\') escape(page, '\')
  endfor
endfunction

" Based on <https://github.com/chengzeyi/fzf-preview.vim/blob/a30d6929c560e46a5c6ea3f8f62e3ab281c3d72c/autoload/fzf_preview/quickfix.vim>.
function! dotfiles#fzf#qflist_fuzzy(is_loclist, fullscreen) abort
  " TODO: build a list from multi-selection
  " TODO: support g:fzf_action
  let get_list_opts = {'items': 0, 'id': 0, 'nr': 0}
  let initial_winid = win_getid()
  let list = a:is_loclist ? getloclist(initial_winid, get_list_opts) : getqflist(get_list_opts)

  let Hl2ansi  = function('dotfiles#fzf#hlgroup_to_ansi')
  let hl_path  = hlexists('qfFileName') ? Hl2ansi('qfFileName') : Hl2ansi('Directory')
  let hl_range = hlexists('qfLineNr')   ? Hl2ansi('qfLineNr')   : Hl2ansi('LineNr')
  let hl_error = hlexists('qfError')    ? Hl2ansi('qfError')    : Hl2ansi('Error')
  let hl_warn  = hlexists('qfWarning')  ? Hl2ansi('qfWarning')  : ''
  let hl_info  = hlexists('qfInfo')     ? Hl2ansi('qfInfo')     : ''
  let hl_note  = hlexists('qfNote')     ? Hl2ansi('qfNote')     : ''
  let type_lookup = {
  \ 'e': hl_error . 'error',   'E': hl_error . 'error',
  \ 'w': hl_warn  . 'warning', 'W': hl_warn  . 'warning',
  \ 'i': hl_info  . 'info',    'I': hl_info  . 'info',
  \ 'n': hl_note  . 'note',    'N': hl_note  . 'note' }
  let formatted_items = map(copy(list.items), function('s:qflist_format_error', [hl_path, hl_range, type_lookup]))

  " Can't close the list window just yet - we'd have nowhere to return.
  execute (a:is_loclist ? 'l' : 'c') . 'open 1'

  let results = fzf#run(fzf#wrap('qflist_fuzzy', fzf#vim#with_preview({
  \ 'source': formatted_items,
  \ 'sink*': function('s:qflist_fuzzy_handler', [a:is_loclist, initial_winid, list]),
  \ 'options': ['--ansi', '--prompt='.(a:is_loclist ? 'LocList' : 'QuickFix').'> ', '--no-multi',
  \   '--layout=reverse-list', "--delimiter=\t", '--with-nth=3..', '--preview-window=hidden',
  \   '--color=fg+:' . dotfiles#fzf#hlgroup_to_fzf_color('QuickFixLine', 'fg'),
  \   '--color=bg+:' . dotfiles#fzf#hlgroup_to_fzf_color('QuickFixLine', 'bg')
  \   ],
  \ 'placeholder': '--tag {2}',
  \ }), a:fullscreen))
  return results
endfunction

" Essentially re-implements the logic of how Nvim draws the qf list:
" <https://github.com/neovim/neovim/blob/v0.6.0/src/nvim/quickfix.c#L3955-L4004>
" <https://github.com/neovim/neovim/blob/v0.6.0/src/nvim/quickfix.c#L3187-L3210>
" <https://github.com/neovim/neovim/blob/v0.6.0/src/nvim/quickfix.c#L3428-L3457>
" <https://github.com/neovim/neovim/blob/v0.6.0/src/nvim/quickfix.c#L3164-L3185>
function! s:qflist_format_error(hl_path, hl_range, type_lookup, item_idx, item) abort
  let reset = "\e[m"

  let is_helpgrep = a:item.type ==# "\1"

  let full_path = ''
  if a:item.bufnr != 0 && bufexists(a:item.bufnr)
    let full_path = fnamemodify(bufname(a:item.bufnr), ':p')
  endif
  let fzf_preview_path = (!empty(full_path) ? full_path : '/dev/null') . '::'

  if !empty(a:item.module)
    let path_part = a:item.module
  elseif is_helpgrep
    let path_part = fnamemodify(full_path, ':t')  " get the tail component
  else
    let path_part = fnamemodify(full_path, ':.')  " shorten the path
  endif
  if !empty(path_part)
    let path_part = a:hl_path . path_part . reset
  endif

  if a:item.lnum > 0
    let range_part = printf('%d', a:item.lnum)
    let fzf_preview_path .= range_part
    if a:item.end_lnum > 0 && a:item.end_lnum != a:item.lnum
      let range_part .= printf('-%d', a:item.end_lnum)
    endif
    if a:item.col > 0
      let range_part .= printf(' col %d', a:item.col)
      if a:item.end_col > 0 && a:item.end_col != a:item.col
        let range_part .= printf('-%d', a:item.end_col)
      endif
    endif

    let type = a:item.type
    if empty(type) && a:item.nr > 0
      let type = 'E'
    endif
    let type_hl_reset = ''
    if has_key(a:type_lookup, type)
      let range_part .= ' ' . reset . a:type_lookup[type]
      let type_hl_reset = reset . a:hl_range
    elseif !empty(type) && !is_helpgrep
      let range_part .= ' ' . type[0]
    endif

    if a:item.nr > 0
      let range_part .= type_hl_reset . printf(' %3d', a:item.nr)
    endif
  elseif !empty(a:item.pattern)
    let range_part = substitute(a:item.pattern, '\n\s*', ' ', 'g')
  else
    let range_part = ''
  endif
  if !empty(range_part)
    let range_part = a:hl_range . range_part . reset
  endif

  let text_part = a:item.text
  if !empty(path_part) || !empty(range_part)
    let text_part = substitute(text_part, '^\s*', '', '')
  endif
  let text_part = substitute(text_part, '\n\s*', ' ', 'g')

  return printf("%d\t%s\t%s|%s| %s", a:item_idx, fzf_preview_path, path_part, range_part, text_part)
endfunction

function! s:qflist_fuzzy_handler(is_loclist, initial_winid, list, lines) abort
  call win_gotoid(a:initial_winid)

  let item_idx = matchstr(get(a:lines, 0, ''), '^\d\+')
  if !empty(item_idx)
    let item_idx = str2nr(item_idx, 10)
    let item = a:list.items[item_idx]

    let get_list_opts = {'id': a:list.id, 'nr': 0}
    let new_list = a:is_loclist ? getloclist(0, get_list_opts) : getqflist(get_list_opts)
    let list_still_exists = new_list.id == a:list.id
    if list_still_exists
      let lc = a:is_loclist ? 'l' : 'c'
      execute new_list.nr . lc . 'history'
      execute (item_idx + 1) . lc . lc
      execute lc . 'close'
      normal! zv
    endif
  endif
endfunction
