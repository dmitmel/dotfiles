" pop-up (completion) menu mappings {{{
  imap <silent><expr> <CR>    pumvisible() ? "\<C-y>" : "\<Plug>delimitMateCR"
  imap <silent><expr> <Esc>   pumvisible() ? "\<C-e>" : "\<Esc>"
  imap <silent><expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
  imap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" }}}

if !g:vim_ide
  function IsCocEnabled()
    return 0
  endfunction
  finish
endif

" coc.nvim {{{
  " list of filetypes (that are added in language-specific scripts) for which
  " coc mappings are enabled
  let g:coc_filetypes = []

  function IsCocEnabled()
    return index(g:coc_filetypes, &filetype) >= 0
  endfunction

  command -nargs=* CocKeywordprg call CocAction('doHover')
  augroup vimrc-coc
    autocmd!
    autocmd FileType * if IsCocEnabled()
      \|let &l:formatexpr = "CocAction('formatSelected')"
      \|let &l:keywordprg = ":CocKeywordprg"
      \|endif
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
  augroup end

  " mappings {{{
    let g:coc_snippet_next = '<Tab>'
    let g:coc_snippet_prev = '<S-Tab>'

    inoremap <silent><expr> <C-Space> coc#refresh()
    inoremap <silent> <A-s> <Cmd>call CocActionAsync('showSignatureHelp')<CR>
    imap <F1> <A-s>

    nmap <silent> [c <Plug>(coc-diagnostic-prev)
    nmap <silent> ]c <Plug>(coc-diagnostic-next)

    nmap <silent> <space>gd <Plug>(coc-definition)
    nmap <silent> <space>gt <Plug>(coc-type-definition)
    nmap <silent> <space>gi <Plug>(coc-implementation)
    nmap <silent> <space>gr <Plug>(coc-references)
    nmap <silent> <F2>      <Plug>(coc-rename)
    nmap <silent> <A-CR>    <Plug>(coc-codeaction-line)
    vmap <silent> <A-CR>    <Plug>(coc-codeaction-selected)
    " nmap <silent> <leader>qf  <Plug>(coc-fix-current)

    nnoremap <silent> <space>l <Cmd>CocList<CR>
    nnoremap <silent> <space>d <Cmd>CocList --auto-preview diagnostics<CR>
    nnoremap <silent> <space>c <Cmd>CocList commands<CR>
    nnoremap <silent> <space>o <Cmd>CocList --auto-preview outline<CR>
    nnoremap <silent> <space>s <Cmd>CocList --interactive symbols<CR>
    nnoremap <silent> <space>e <Cmd>CocList extensions<CR>
    nnoremap <silent> <space>h <Cmd>CocPrev<CR>
    nnoremap <silent> <space>k <Cmd>CocPrev<CR>
    nnoremap <silent> <space>l <Cmd>CocNext<CR>
    nnoremap <silent> <space>j <Cmd>CocNext<CR>
    nnoremap <silent> <space>p <Cmd>CocListResume<CR>
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

  let g:coc_global_extensions = []
  let g:coc_user_config = {}

  let g:coc_global_extensions += ['coc-snippets']
  let g:coc_user_config['diagnostic'] = {
  \ 'virtualText': v:true,
  \ 'virtualTextCurrentLineOnly': v:false,
  \ 'enableMessage': 'jump',
  \ 'errorSign': 'XX',
  \ 'warningSign': '!!',
  \ }
  let g:coc_user_config['suggest.floatEnable'] = v:false

  runtime! coc-languages/*.vim

" }}}
