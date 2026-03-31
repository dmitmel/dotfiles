function! airline#extensions#avoid_nvim_float_windows#init(ext) abort
  call a:ext.add_statusline_func('airline#extensions#avoid_nvim_float_windows#apply')
  call a:ext.add_inactive_statusline_func('airline#extensions#avoid_nvim_float_windows#apply')
endfunction

function! airline#extensions#avoid_nvim_float_windows#apply(builder, context) abort
  if !empty(nvim_win_get_config(win_getid(a:context.winnr)).relative)
    call setwinvar(a:context.winnr, 'airline_disable_statusline', 1)
    return -1  " Halt the statusline rendering process
  endif
endfunction
