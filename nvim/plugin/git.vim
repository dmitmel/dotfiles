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
  nnoremap <leader>gl :Gclog<CR>
  nnoremap <leader>gp :Git push
" }}}
