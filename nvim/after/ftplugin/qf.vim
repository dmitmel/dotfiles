" <https://github.com/romainl/vim-qf/blob/4fe7e33a514874692d6897edd1acaaa46d9fb646/after/ftplugin/qf.vim#L48-L94>
if exists('g:qf_mapping_ack_style')
  if b:qf_isLoc == 1
    nnoremap <silent> <buffer> <Esc> :<C-u>lclose<CR>
    nnoremap <silent> <buffer>   q   :<C-u>lclose<CR>
  else
    nnoremap <silent> <buffer> <Esc> :<C-u>cclose<CR>
    nnoremap <silent> <buffer>   q   :<C-u>cclose<CR>
  endif

  nmap <buffer> ( <Plug>(qf_previous_file)
  nmap <buffer> ) <Plug>(qf_next_file)

  nnoremap <silent> <buffer> <Plug>dotfiles_qf_height :<C-u>call dotutils#readjust_qf_list_height()<CR>
  nmap <buffer> <C-p> <Plug>(qf_older)<Plug>dotfiles_qf_height
  nmap <buffer> <C-n> <Plug>(qf_newer)<Plug>dotfiles_qf_height

  nmap <buffer> <CR> <CR>zv

  let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
  let b:undo_ftplugin .= "| silent! nunmap <buffer> <Esc>"
  let b:undo_ftplugin .= "| silent! nunmap <buffer> q"
  let b:undo_ftplugin .= "| silent! nunmap <buffer> ("
  let b:undo_ftplugin .= "| silent! nunmap <buffer> )"
  let b:undo_ftplugin .= "| silent! nunmap <buffer> <Plug>dotfiles_qf_height"
  let b:undo_ftplugin .= "| silent! nunmap <buffer> <C-p>"
  let b:undo_ftplugin .= "| silent! nunmap <buffer> <C-n>"
  let b:undo_ftplugin .= "| silent! nunmap <buffer> <CR>"
endif
