function! s:get_cmd() abort
  return luaeval("(FzfLua.get_info() or {}).cmd or ''")
endfunction

function! s:get_preview() abort
  for winid in nvim_list_wins()
    if getwinvar(winid, 'fzf_lua_preview', 0)
      let title = get(nvim_win_get_config(winid), 'title', [])
      return join(map(title, 'trim(v:val[0])'), ' ')
    endif
  endfor
  return ''
endfunction

function! airline#extensions#fzf_lua#init(ext) abort
  call a:ext.add_statusline_func('airline#extensions#fzf_lua#apply')
  call a:ext.add_inactive_statusline_func('airline#extensions#fzf_lua#apply')
  call airline#parts#define_function('fzf_lua_cmd', expand('<SID>').'get_cmd')
  call airline#parts#define_function('fzf_lua_preview', expand('<SID>').'get_preview')
  call airline#parts#define('fzf_lua_title', { 'raw': 'FZF', 'accent': 'bold' })
endfunction

function! airline#extensions#fzf_lua#apply(builder, ctx) abort
  if getwinvar(a:ctx.winnr, 'fzf_lua_win', 0) || getwinvar(a:ctx.winnr, 'fzf_lua_preview', 0)
    call a:builder.add_section_spaced('airline_a', airline#section#create_left(['fzf_lua_title']))
    call a:builder.add_section_spaced('airline_b', airline#section#create(['fzf_lua_cmd']))
    call a:builder.add_section_spaced('airline_c', '')
    call a:builder.split()
    call a:builder.add_section_spaced('airline_x', airline#section#create(['fzf_lua_preview']))
    return 1
  endif
endfunction
