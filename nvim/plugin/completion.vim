" Disable showing completion-related messages in the bottom of the screen, such
" as "match X of Y", "The only match", "Pattern not found" etc.
set shortmess+=c

" Don't let the built-in completion mode (i_CTRL-N and i_CTRL-P) take results
" from included files. That is slow and imprecise, tags are much better for
" that.
set complete-=i

" <https://github.com/neoclide/coc.nvim/blob/705135211e84725766e434f59e63ae3592c609d9/src/completion/index.ts#L595-L600>
" on the other hand
" <https://github.com/hrsh7th/nvim-compe/blob/077329e6bd1704d1acdff087ef1a73df23e92789/autoload/compe.vim#L46-L53>
set completeopt=menuone,noselect


if dotfiles#plugman#is_registered('nvim-snippy')  " {{{

  lua <<EOF
  local snippy = require('snippy')
  snippy.setup({
    scopes = {
      cpp = { '_', 'c', 'cpp' },
      typescript = { '_', 'javascript', 'typescript' },
    },
  })
EOF

  " Stolen from <https://github.com/hrsh7th/vim-vsnip/blob/fd13f3fb09823cdefb2c9bebb614a13afd1920cc/plugin/vsnip.vim#L74-L76>
  snoremap <expr> <BS> ("\<BS>" . (getcurpos()[2] == col('$') - 1 ? 'a' : 'i'))

endif  " }}}


if dotfiles#plugman#is_registered('nvim-cmp')  " {{{

  lua require('dotfiles.completion')

  if dotfiles#plugman#is_registered('cmp-nvim-lsp')
    lua require('cmp_nvim_lsp').update_capabilities(require('dotfiles.lsp.ignition').default_config.capabilities)
  endif

endif  " }}}


let s:diagnostic_sign_texts = { 'Error': 'XX', 'Warn': '!!', 'Info': '>>', 'Hint': '>>' }


if dotfiles#plugman#is_registered('nvim-lspconfig')  " {{{

  lua <<EOF
  local log = require('vim.lsp.log')
  if log.set_format_func then
    log.set_format_func(function(arg)
      return vim.inspect(arg, { newline = ' ', indent = '' })
    end)
  end
  local log_level_var = vim.env.NVIM_LSP_LOG_LEVEL
  if log_level_var ~= nil and log_level_var ~= '' then
    log.set_level(vim.env.NVIM_LSP_LOG_LEVEL)
  end
EOF

  " Ensure that the built-in LSP module is initialized first.
  lua require('vim.lsp')

  " <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/diagnostic.lua#L923-L963>
  " <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/diagnostic.lua#L209-L231>
  for s:severity in range(4)
    let s:sign_opts = { 'text': '', 'texthl': '', 'linehl': '', 'numhl': '' }

    let s:name_prefix = has('nvim-0.6.0') ? 'Diagnostic' : 'LspDiagnostics'
    let s:severity_name = ['Error', 'Warn', 'Info', 'Hint'][s:severity]
    let s:sign_opts.text = s:diagnostic_sign_texts[s:severity_name]
    if !has('nvim-0.6.0')
      let s:severity_name = ['Error', 'Warning', 'Information', 'Hint'][s:severity]
    endif
    let s:sign_opts.texthl = s:name_prefix.'Sign'.s:severity_name
    let s:sign_opts.numhl = s:name_prefix.'Sign'.s:severity_name
    if get(g:, 'dotfiles_lsp_diagnostics_gui_style')
      let s:sign_opts.linehl = s:name_prefix.'Line'.s:severity_name
    endif

    call sign_define(s:name_prefix.'Sign'.s:severity_name, s:sign_opts)
  endfor

  lua require('dotfiles.lsp.ignition').install_compat()
  lua require('dotfiles.lsp.ignition').setup()
  lua require('lspconfig')
  lua require('dotfiles.lsp.dummy_entry_plug')
  lua <<EOF
  require('dotfiles.lsp.ignition').add_default_config({
    flags = {
      debounce_text_changes = 100,
    },
  })
EOF

  lua require('dotfiles.lsp.basic_handlers')
  if has('nvim-0.6.0')
    lua require('dotfiles.lsp.custom_ui')
  endif
  if has('nvim-0.6.0')
    lua require('dotfiles.lsp.diagnostics')
  else
    lua require('dotfiles.lsp.diagnostics_old')
  endif
  lua require('dotfiles.lsp.float')
  lua require('dotfiles.lsp.global_settings')
  lua require('dotfiles.lsp.hover')
  lua require('dotfiles.lsp.markup')
  lua require('dotfiles.lsp.progress')
  lua require('dotfiles.lsp.signature_help')
  lua require('dotfiles.lsp.symbols')
  lua require('dotfiles.lsp.utils')

  " commands {{{

    if has('nvim-0.6.0')
      command! -nargs=0 -bar LspDiagnostics lua vim.diagnostic.setqflist({severity={min='INFO'}})
    else
      command! -nargs=0 -bar LspDiagnostics lua vim.lsp.diagnostic.set_qflist({severity_limit='Information'})
    endif
    command! -nargs=0 -bar LspOpenLog lua vim.call('dotfiles#utils#jump_to_file', vim.lsp.get_log_path())
    command! -nargs=0 -bar -range LspFormat lua if <range> == 0 then vim.lsp.buf.formatting() else vim.lsp.buf.range_formatting(nil, {<line1>, 0}, {<line2>, #vim.fn.getline(<line2>)}) end
    command! -nargs=0 -bar LspFormatSync lua vim.lsp.buf.formatting_sync()
    command! -nargs=+ -bar LspWorkspaceSymbols lua vim.lsp.buf.workspace_symbol(<q-args>)

  " }}}

  " mappings {{{

    " NOTE: These global mappings must not override Vim's default ones, but the
    " Lua part of the LSP configuration may create buffer-local shorthands in
    " on_attach (e.g. `gd -> <space>gd`).
    nnoremap <silent> <space>gd  <Cmd>lua vim.lsp.buf.definition()<CR>
    nnoremap <silent> <space>gD  <Cmd>lua vim.lsp.buf.declaration()<CR>
    nnoremap <silent> <space>gt  <Cmd>lua vim.lsp.buf.type_definition()<CR>
    nnoremap <silent> <space>gi  <Cmd>lua vim.lsp.buf.implementation()<CR>
    nnoremap <silent> <space>gr  <Cmd>lua vim.lsp.buf.references({includeDeclaration=false})<CR>
    nnoremap <silent> <F2>       <Cmd>lua vim.lsp.buf.rename()<CR>
    nnoremap <silent> <A-CR>     <Cmd>lua vim.lsp.buf.code_action()<CR>
    xnoremap <silent> <A-CR>    :<C-u>lua vim.lsp.buf.range_code_action()<CR>
    nnoremap <silent> <space>K   <Cmd>lua vim.lsp.buf.hover()<CR>
    xnoremap <silent> <space>K  :<C-u>lua vim.lsp.buf.range_hover()<CR>
    nnoremap <silent> <space>s   <Cmd>lua vim.lsp.buf.signature_help()<CR>
    inoremap <silent> <F1>       <Cmd>lua vim.lsp.buf.signature_help()<CR>
    if has('nvim-0.6.0')
      " The mnemonic here is "diaGnostic". Very intuitive, I know, but `]d` and
      " `[d` are taken by the line duplication mappings. The previous mappings
      " for diagnostics jumps used `c`, which meant 'coc', obviously, but that
      " one is taken by the mappings for Git hunk jumps, and I really wanted to
      " untangle those two.
      noremap <silent> [g       <Cmd>lua vim.diagnostic.goto_prev({wrap=vim.o.wrapscan})<CR>
      noremap <silent> ]g       <Cmd>lua vim.diagnostic.goto_next({wrap=vim.o.wrapscan})<CR>
      sunmap [g
      sunmap ]g
      nnoremap <silent> <A-d>    <Cmd>lua vim.diagnostic.open_float(nil,{scope='line'})<CR>
    else
      noremap <silent> [g       <Cmd>lua vim.lsp.diagnostic.goto_prev({wrap=vim.o.wrapscan})<CR>
      noremap <silent> ]g       <Cmd>lua vim.lsp.diagnostic.goto_next({wrap=vim.o.wrapscan})<CR>
      sunmap [g
      sunmap ]g
      nnoremap <silent> <A-d>    <Cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>
    endif
    nnoremap <silent> <space>d   <Cmd>LspDiagnostics<CR>
    nnoremap <silent> <space>f   <Cmd>LspFormat<CR>
    xnoremap <silent> <space>f       :LspFormat<CR>
    nnoremap <silent> <space>o   <Cmd>lua vim.lsp.buf.document_symbol()<CR>
    nnoremap          <space>w       :LspWorkspaceSymbols<space>
    nnoremap <silent> <space>c   <Cmd>call fzf#vim#commands({'options':['--query=Lsp']})<CR>
    nnoremap <silent> <space>e   <Cmd>LspInfo<CR>

    " Create shorthands overriding default mappings which make sense when a
    " language server is connected. Note that these are not created in
    " `on_attach` or similar because the `buf_any_client_supports_method`
    " checks will correctly respond to the server being stopped, for instance.
    nmap <silent><expr> K  v:lua.vim.lsp.buf_any_client_supports_method(0, 'textDocument/hover')       ? "<space>K"  : "K"
    nmap <silent><expr> gd v:lua.vim.lsp.buf_any_client_supports_method(0, 'textDocument/definition')  ? "<space>gd" : "gd"
    nmap <silent><expr> gD v:lua.vim.lsp.buf_any_client_supports_method(0, 'textDocument/declaration') ? "<space>gD" : "gD"
    nmap <silent><expr> gr v:lua.vim.lsp.buf_any_client_supports_method(0, 'textDocument/references')  ? "<space>gr" : "gr"

  " }}}

  augroup dotfiles_lsp
    autocmd!
    autocmd User LspIgnitionBufAttach setlocal omnifunc=v:lua.vim.lsp.omnifunc
    if has('nvim-0.6.0')
      autocmd User LspIgnitionBufAttach setlocal formatexpr=v:lua.vim.lsp.formatexpr
    endif
  augroup END

  runtime! dotfiles/lspconfigs/*.lua

endif  " }}}


if dotfiles#plugman#is_registered('coc.nvim')  " {{{

  " let g:coc_node_args = ['-r', expand('~/.config/yarn/global/node_modules/source-map-support/register'), '--nolazy', '--inspect']

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

    imap <silent><expr> <CR>    pumvisible() ? "\<C-y>" : "\<Plug>delimitMateCR"
    imap <silent><expr> <Esc>   pumvisible() ? "\<C-e>" : "\<Esc>"
    imap <silent><expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
    imap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
    inoremap <silent><expr> <C-Space> coc#refresh()
    inoremap <silent> <A-s> <Cmd>call CocActionAsync('showSignatureHelp')<CR>
    imap <F1> <A-s>

    nmap <silent> [d <Plug>(coc-diagnostic-prev)
    nmap <silent> ]d <Plug>(coc-diagnostic-next)

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
  \ 'errorSign':   s:diagnostic_sign_texts.Error,
  \ 'warningSign': s:diagnostic_sign_texts.Warn,
  \ 'infoSign':    s:diagnostic_sign_texts.Info,
  \ 'hintSign':    s:diagnostic_sign_texts.Hint,
  \ }
  let g:coc_user_config['suggest.floatEnable'] = v:false
  let g:coc_user_config['workspace.progressTarget'] = 'statusline'
  let g:coc_user_config['list.selectedSignText'] = '> '
  let g:coc_user_config['coc.preferences.maxFileSize'] = '1MB'

  runtime! coc-languages/*.vim

  if !g:dotfiles_build_coc_from_source
    let g:coc_global_extensions = get(g:, 'coc_global_extensions', [])
    call extend(g:coc_global_extensions, keys(g:dotfiles_coc_extensions))
  endif

endif  " }}}
