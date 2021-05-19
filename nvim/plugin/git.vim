" mappings {{{
  let g:gitgutter_map_keys = 0
  nnoremap <leader>gg :<C-u>G
  nnoremap <leader>g  :<C-u>Git<space>
  nnoremap <leader>gs :<C-u>vertical Git<CR>
  nnoremap <leader>gd :<C-u>Gdiffsplit
  nnoremap <leader>gb :<C-u>Git blame<CR>
  nnoremap <leader>gw :<C-u>GBrowse<CR>
  nnoremap <leader>gW :<C-u>.GBrowse<CR>
  nnoremap <leader>gc :<C-u>Git commit %
  nnoremap <leader>gC :<C-u>Git commit --amend
  nnoremap <leader>gl :<C-u>Gclog<CR>
  nnoremap <leader>gp :<C-u>Git push
  nnoremap <leader>gP :<C-u>Git push --force-with-lease
  " Jump to the next/previous change in the diff mode because I replace the
  " built-in mappings with coc.nvim's for jumping through diagnostics.
  nnoremap [g [c
  nnoremap ]g ]c
" }}}

" Fugitive.vim handlers {{{

  if !exists('g:fugitive_browse_handlers')
    let g:fugitive_browse_handlers = []
  endif

  if index(g:fugitive_browse_handlers, function('dotfiles#fugitive#aur#handler')) < 0
    call insert(g:fugitive_browse_handlers, function('dotfiles#fugitive#aur#handler'))
  endif

" }}}
