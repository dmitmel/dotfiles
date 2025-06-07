function! airline#extensions#snacks_picker#init(ext) abort
  call a:ext.add_statusline_func('airline#extensions#snacks_picker#apply')
  call a:ext.add_inactive_statusline_func('airline#extensions#snacks_picker#apply')
  for part in ['title', 'pos', 'list', 'percent', 'found', 'selected', 'file']
    call airline#parts#define_function('snacks_picker_'.part, expand('<SID>').part.'_part')
  endfor
  call airline#parts#define_accent('snacks_picker_pos', 'bold')
  call airline#parts#define_accent('snacks_picker_list', 'bold')
endfunction

function! airline#extensions#snacks_picker#apply(builder, context) abort
  if getbufvar(a:context.bufnr, '&filetype') ==# 'snacks_layout_box'
    let ns = 'snacks_picker_'
    call a:builder.add_section_spaced('airline_a', airline#section#create_left(['mode']))
    call a:builder.add_section_spaced('airline_b', airline#section#create([ns.'title']))
    call a:builder.add_section_spaced('airline_c', airline#section#create([ns.'file']))
    call a:builder.split()
    call a:builder.add_section_spaced('airline_y', airline#section#create([ns.'selected', ns.'found']))
    call a:builder.add_section_spaced('airline_z', airline#section#create([ns.'percent', ns.'pos', ns.'list']))
    return 1
  endif
endfunction

let s:get = { what -> v:lua.dotfiles.snacks_picker_info(what) }

function! s:title_part() abort
  return s:get('title') . ' picker'
endfunction

function! s:pos_part() abort
  return g:airline_symbols.linenr . printf('%2d', s:get('pos'))
endfunction

function! s:list_part() abort
  return '/' . printf('%d', s:get('list')) . g:airline_symbols.maxlinenr
endfunction

function! s:found_part() abort
  return printf('#%d/%d', s:get('list'), s:get('found'))
endfunction

function! s:percent_part() abort
  let pos = s:get('pos')
  let list = s:get('list')
  return (pos > 0 && list > 0) ? printf('%2d%% ', pos * 100 / list) : ''
endfunction

function! s:selected_part() abort
  let selected = s:get('selected')
  return selected > 0 ? printf('(%d)', selected) : ''
endfunction

function! s:file_part() abort
  let file = s:get('file')
  return !empty(file) ? fnamemodify(file, ':~:.') : ''
endfunction
