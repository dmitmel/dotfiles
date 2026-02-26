if !exists('*api_info') | finish | endif

function! dotfiles#nvim#api_cheat_sheet#format(info) abort
  let result = []
  for fn_data in a:info.functions
    if has_key(fn_data, 'deprecated_since') | continue | endif
    call extend(result, ['function ', fn_data.name, '('])
    let param_idx = 0
    for [param_type, param_name] in fn_data.parameters
      if param_idx > 0
        call add(result, ', ')
      endif
      call extend(result, [param_name, ': ', param_type])
      let param_idx += 1
    endfor
    call extend(result, ['): ', fn_data.return_type, ';'])
    call add(result, "\n")
  endfor
  return join(result, '')
endfunction

function! dotfiles#nvim#api_cheat_sheet#print() abort
  echo dotfiles#nvim#api_cheat_sheet#format(api_info())
endfunction

function! dotfiles#nvim#api_cheat_sheet#open() abort
  let text = dotfiles#nvim#api_cheat_sheet#format(api_info())

  new [Neovim API Reference]
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nomodeline

  call setbufline('%', 1, split(text, "\n"))
  setlocal syntax=typescript colorcolumn=
endfunction
