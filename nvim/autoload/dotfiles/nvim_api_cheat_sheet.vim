if !exists('*api_info') | finish | endif

function! dotfiles#nvim_api_cheat_sheet#print() abort
  let api_info = api_info()
  for fn_data in api_info.functions
    if has_key(fn_data, 'deprecated_since') | continue | endif
    let fn_str = ['fn ', fn_data.name, '(']
    let param_idx = 0
    for [param_type, param_name] in fn_data.parameters
      if param_idx > 0
        call add(fn_str, ', ')
      endif
      call extend(fn_str, [param_name, ': ', param_type])
      let param_idx += 1
    endfor
    call extend(fn_str, [') -> ', fn_data.return_type])
    echo join(fn_str, '')
  endfor
endfunction
