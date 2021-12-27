" <https://github.com/romainl/vim-qf/blob/4fe7e33a514874692d6897edd1acaaa46d9fb646/after/ftplugin/qf.vim#L48-L94>
if exists('g:qf_mapping_ack_style')
  if b:qf_isLoc == 1
    nnoremap <silent> <buffer> <Esc> <Cmd>lclose<CR>
  else
    nnoremap <silent> <buffer> <Esc> <Cmd>cclose<CR>
  endif
  nmap <buffer> ( <Plug>(qf_previous_file)
  nmap <buffer> ) <Plug>(qf_next_file)
  nmap <buffer> <C-p> <Plug>(qf_older)<Cmd>call dotfiles#utils#readjust_qf_list_height()<CR>
  nmap <buffer> <C-n> <Plug>(qf_newer)<Cmd>call dotfiles#utils#readjust_qf_list_height()<CR>
  nmap <buffer> <CR> <CR>zv
  call dotfiles#utils#undo_ftplugin_hook(join([
  \ 'exe "silent! nunmap <buffer> <Esc>"',
  \ 'exe "silent! nunmap <buffer> ("',
  \ 'exe "silent! nunmap <buffer> )"',
  \ 'exe "silent! nunmap <buffer> <C-p>"',
  \ 'exe "silent! nunmap <buffer> <C-n>"',
  \ 'exe "silent! nunmap <buffer> <CR>"',
  \ ], ' | '))
endif
