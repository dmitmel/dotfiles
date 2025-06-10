exe dotfiles#ft#set('&colorcolumn', '')

nnoremap <buffer> q <C-w>c
call dotfiles#ft#undo_map('n', ['q'])

" <https://github.com/romainl/vim-qf/blob/4fe7e33a514874692d6897edd1acaaa46d9fb646/after/ftplugin/qf.vim#L48-L94>
if exists('g:qf_mapping_ack_style')
  nmap <buffer> ( <Plug>(qf_previous_file)
  nmap <buffer> ) <Plug>(qf_next_file)

  " Essentially a part of <https://github.com/romainl/vim-qf/blob/65f115c350934517382ae45198a74232a9069c2a/autoload/qf.vim#L86-L108>.
  function! s:readjust_list_height() abort
    let max_height = get(g:, 'qf_max_height', 10) < 1 ? 10 : get(g:, 'qf_max_height', 10)
    if get(b:, 'qf_isLoc', 0)
      execute 'lclose|' . (get(g:, 'qf_auto_resize', 1) ? min([max_height, len(getloclist(0))]) : '') . 'lwindow'
    else
      execute 'cclose|' . (get(g:, 'qf_auto_resize', 1) ? min([max_height, len(getqflist())]) : '') . 'cwindow'
    endif
  endfunction
  nnoremap <silent><buffer> <SID>readjust_list_height :<C-u>call <SID>readjust_list_height()<CR>

  nmap <buffer> <C-p> <Plug>(qf_older)<SID>readjust_list_height
  nmap <buffer> <C-n> <Plug>(qf_newer)<SID>readjust_list_height

  nmap <buffer> <CR> <CR>zv

  call dotfiles#ft#undo_map('n', ['(', ')', '<Plug>dotfiles_qf_height', '<C-p>', '<C-n>', '<CR>'])
endif
