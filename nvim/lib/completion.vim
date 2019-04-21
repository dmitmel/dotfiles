" pop-up (completion) menu mappings {{{
  imap <silent><expr> <CR> pumvisible() ? "\<C-y>" : "\<Plug>delimitMateCR"
  imap <silent><expr> <Esc> pumvisible() ? "\<C-e>" : "\<Esc>"
  imap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
  imap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" }}}

" coc.nvim {{{
  " list of filetypes (that are added in language-specific scripts) for which
  " coc mappings are enabled
  let g:coc_filetypes = []

  function IsCocEnabled()
    return index(g:coc_filetypes, &filetype) >= 0
  endfunction

  augroup vimrc-coc
    autocmd!
    autocmd FileType * if IsCocEnabled()
      \|let &l:formatexpr = "CocAction('formatSelected')"
      \|let &l:keywordprg = ":call CocAction('doHover')"
      \|endif
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
  augroup end

  " mappings {{{
    let g:coc_snippet_next = '<Tab>'
    let g:coc_snippet_prev = '<S-Tab>'

    inoremap <silent><expr> <C-Space> coc#refresh()

    nmap <silent> [c <Plug>(coc-diagnostic-prev)
    nmap <silent> ]c <Plug>(coc-diagnostic-next)

    nmap <silent> <leader>jd <Plug>(coc-definition)
    nmap <silent> <leader>jt <Plug>(coc-type-definition)
    nmap <silent> <leader>ji <Plug>(coc-implementation)
    nmap <silent> <leader>jr <Plug>(coc-references)
    nmap <silent> <F2>       <Plug>(coc-rename)
    nmap <silent> <A-CR>     <Plug>(coc-codeaction)
    vmap <silent> <A-CR>     <Plug>(coc-codeaction-selected)
    " nmap <silent> <leader>qf  <Plug>(coc-fix-current)

    nnoremap <silent> <space>l :CocList<CR>
    nnoremap <silent> <space>d :CocList --auto-preview diagnostics<CR>
    nnoremap <silent> <space>c :CocList commands<CR>
    nnoremap <silent> <space>o :CocList --auto-preview outline<CR>
    nnoremap <silent> <space>s :CocList --interactive symbols<CR>
    nnoremap <silent> <space>h :CocPrev<CR>
    nnoremap <silent> <space>k :CocPrev<CR>
    nnoremap <silent> <space>l :CocNext<CR>
    nnoremap <silent> <space>j :CocNext<CR>
    nnoremap <silent> <space>p :CocListResume<CR>
  " }}}

  " CocFormat {{{
    function s:CocFormat(range, line1, line2) abort
      if a:range == 0
        call CocAction('format')
      else
        call cursor(a:line1, 1)
        normal! V
        call cursor(a:line2, 1)
        call CocAction('formatSelected', 'V')
      endif
    endfunction
    command! -nargs=0 -range -bar CocFormat call s:CocFormat(<range>, <line1>, <line2>)
  " }}}

  call coc#add_extension('coc-snippets')
  call coc#config('diagnostic', { 'virtualText': v:true, 'enableMessage': 'jump' })
" }}}
