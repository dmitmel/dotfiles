exe dotfiles#ft#set('&colorcolumn', '')
exe dotfiles#ft#set('&signcolumn', 'auto')

call dotfiles#ft#set('disable_secure_modelines', 1)

nnoremap <buffer> q <C-w>c
call dotfiles#ft#undo_map('n', ['q'])

if b:qf_isLoc
  " Transfers the contents of a loclist into the quickfix list.
  nnoremap <buffer><silent> <A-q> :<C-u>call <SID>loc2qf()<CR>
  function! s:loc2qf() abort
    let info = getloclist(0, { 'items': 1, 'title': 1, 'quickfixtextfunc': 1 })
    let info.idx = getloclist(0, { 'idx': 0 }).idx  " Select the same item that was selected
    let info.nr = '$'  " Push to the end of the quickfix list stack
    call setqflist([], ' ', info)
    lclose
    call qf#OpenQuickfix()
  endfunction
else
  nnoremap <buffer><silent> <A-q> <Nop>
endif

if !exists('s:in_delete_operator')
  function! s:delete_operator(type) abort
    if a:type is# 'start'
      let &opfunc = expand('<SID>') . 'delete_operator'
      return 'g@'
    endif

    let GetList = b:qf_isLoc ? function('getloclist', [0]) : function('getqflist')
    let SetList = b:qf_isLoc ? function('setloclist', [0]) : function('setqflist')

    let [start, end] = [line("'["), line("']")]
    let info = GetList({ 'items': 1, 'idx': 0 })
    call remove(info.items, start - 1, end - 1)

    " Adjust the current item index.
    if info.idx > end
      let info.idx -= end - start + 1
    elseif info.idx > start
      let info.idx = start
    endif

    let view = winsaveview()

    let s:in_delete_operator = 1
    try
      call SetList([], 'r', info)
    finally
      unlet s:in_delete_operator
    endtry

    call winrestview(view)
  endfunction
endif

" I disabled this operator because it is hard to use. Other methods for
" filtering the quickfix list provided by nvim-bqf and vim-qf are much handier
" because they create a new list. The code of the operator itself is left for
" future reference.
if 0
  nnoremap <buffer><expr> d  <SID>delete_operator('start')
  nnoremap <buffer><expr> dd <SID>delete_operator('start') . '_'
  xnoremap <buffer><expr> d  <SID>delete_operator('start')
endif

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
