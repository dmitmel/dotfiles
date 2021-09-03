" pop-up (completion) menu mappings {{{
  imap <silent><expr> <CR>    pumvisible() ? "\<C-y>" : "\<Plug>delimitMateCR"
  imap <silent><expr> <Esc>   pumvisible() ? "\<C-e>" : "\<Esc>"
  imap <silent><expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
  imap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" }}}

if !g:vim_ide
  finish
endif

" coc.nvim {{{

  let g:dotfiles_coc_extensions = {}

  " set of filetypes (that are added in language-specific scripts) for which
  " coc mappings are enabled
  let g:dotfiles_coc_filetypes = {}

  command! -nargs=* CocKeywordprg call CocAction('doHover')
  augroup dotfiles_coc
    autocmd!
    autocmd FileType * if has_key(g:dotfiles_coc_filetypes, &filetype)
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
    xmap <silent> <A-CR>    <Plug>(coc-codeaction-selected)
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
    function! s:CocFormat(range, line1, line2) abort
      if !has_key(g:dotfiles_coc_filetypes, &filetype) | return | endif
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

  " Stolen from <https://github.com/keanuplayz/dotfiles/blob/097aaf4ae3721b27c7fc341c6c7b99d78c7d9338/nvim/plugin/commands.vim#L1>
  command! -nargs=0 -bar CocOrganizeImports call CocAction('organizeImport')

  let g:coc_user_config = {}

  call extend(g:dotfiles_coc_extensions, {'coc-snippets': 1})
  let g:coc_user_config['diagnostic'] = {
  \ 'virtualText': v:true,
  \ 'virtualTextCurrentLineOnly': v:false,
  \ 'enableMessage': 'jump',
  \ 'errorSign': 'XX',
  \ 'warningSign': '!!',
  \ }
  let g:coc_user_config['suggest.floatEnable'] = v:false
  let g:coc_user_config['workspace.progressTarget'] = 'statusline'
  let g:coc_user_config['list.selectedSignText'] = '> '

  runtime! coc-languages/*.vim

  if !g:dotfiles_build_coc_from_source
    let g:coc_global_extensions = get(g:, 'coc_global_extensions', [])
    call extend(g:coc_global_extensions, keys(g:dotfiles_coc_extensions))
  endif

" }}}
