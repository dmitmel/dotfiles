" <https://github.com/romainl/vim-qf/blob/4fe7e33a514874692d6897edd1acaaa46d9fb646/after/ftplugin/qf.vim#L48-L94>
if exists("g:qf_mapping_ack_style")
  if b:qf_isLoc == 1
    nnoremap <silent> <buffer> Q     <Cmd>lclose<CR>
    nnoremap <silent> <buffer> <Esc> <Cmd>lclose<CR>
  else
    nnoremap <silent> <buffer> Q     <Cmd>cclose<CR>
    nnoremap <silent> <buffer> <Esc> <Cmd>cclose<CR>
  endif
  call dotfiles#utils#undo_ftplugin_hook('exe "nunmap <buffer> Q" | exe "nunmap <buffer> <Esc>"')
endif
