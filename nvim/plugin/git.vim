" mappings {{{
  let g:gitgutter_map_keys = 0
  nnoremap <leader>gg :G
  nnoremap <leader>g  :Git<space>
  nnoremap <leader>gs :vertical Git<CR>
  nnoremap <leader>gd :Gdiffsplit
  nnoremap <leader>gb :Git blame<CR>
  nnoremap <leader>gw :GBrowse<CR>
  nnoremap <leader>gW :.GBrowse<CR>
  nnoremap <leader>gc :Git commit %
  nnoremap <leader>gC :Git commit --amend
  nnoremap <leader>gl :Gclog<CR>
  nnoremap <leader>gp :Git push
  nnoremap <leader>gP :Git push --force-with-lease
" }}}

" Fugitive.vim handlers {{{

  if !exists('g:fugitive_browse_handlers')
    let g:fugitive_browse_handlers = []
  endif

  if index(g:fugitive_browse_handlers, function('dotfiles#fugitive#aur#handler')) < 0
    call insert(g:fugitive_browse_handlers, function('dotfiles#fugitive#aur#handler'))
  endif

" }}}
