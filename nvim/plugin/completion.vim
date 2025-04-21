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


if dotplug#has('nvim-snippy')  " {{{

  function! s:get_snippet_scopes(scopes) abort
    call extend(a:scopes, get(b:, 'dotfiles_snippets_extra_scopes', []))
    let seen = {}
    let deduped = []
    for scope in a:scopes
      if !has_key(seen, scope)
        call add(deduped, scope)
        let seen[scope] = 1
      endif
    endfor
    return deduped
  endfunction

  lua <<EOF
  local snippy = require('snippy')
  local sid = vim.fn.expand('<SID>')
  snippy.setup({
    scopes = {
      _ = vim.funcref(sid .. 'get_snippet_scopes'),
    },
  })
EOF

  " Stolen from <https://github.com/hrsh7th/vim-vsnip/blob/fd13f3fb09823cdefb2c9bebb614a13afd1920cc/plugin/vsnip.vim#L74-L76>
  snoremap <expr> <BS> ("\<BS>" . (getcurpos()[2] == col('$') - 1 ? 'a' : 'i'))

endif  " }}}


if dotplug#has('nvim-cmp')  " {{{

  lua require('dotfiles.completion')

  if dotplug#has('cmp-nvim-lsp')
    lua require('cmp_nvim_lsp').update_capabilities(require('dotfiles.lsp.ignition').default_config.capabilities)
  endif

endif  " }}}


let s:diagnostic_sign_texts = { 'Error': 'XX', 'Warn': '!!', 'Info': '>>', 'Hint': '>>' }


if get(g:, 'dotfiles_use_nvimlsp', 0)  " {{{

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
    command! -nargs=0 -bar LspOpenLog lua vim.call('dotutils#jump_to_file', vim.lsp.get_log_path())
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


if dotplug#has('coc.nvim')  " {{{

  " let g:coc_node_args = ['-r', expand('~/.config/yarn/global/node_modules/source-map-support/register'), '--nolazy', '--inspect']

  let g:dotfiles_coc_extensions = {}

  " set of filetypes (that are added in language-specific scripts) for which
  " coc mappings are enabled
  let g:dotfiles_coc_filetypes = {}

  function! s:coc_buf_supports(provider) abort
    return g:coc_service_initialized && CocAction('ensureDocument') && CocHasProvider(a:provider)
  endfunction

  " mappings {{{
    let g:coc_snippet_next = '<Tab>'
    let g:coc_snippet_prev = '<S-Tab>'

    imap <silent><expr> <CR>    coc#pum#visible() ? "\<C-y>" : "\<Plug>delimitMateCR"
    " imap <silent><expr> <Esc>   coc#pum#visible() ? "\<C-e>" : "\<Esc>"
    imap <silent><expr> <Tab>   coc#pum#visible() ? "\<C-n>" : "\<Tab>"
    imap <silent><expr> <S-Tab> coc#pum#visible() ? "\<C-p>" : "\<S-Tab>"
    inoremap <silent><expr> <Down> coc#pum#visible() ? coc#pum#next(0) : exists("b:dotfiles_prose_mode") ? "\<C-o>g\<Down>" : "\<Down>"
    inoremap <silent><expr> <Up>   coc#pum#visible() ? coc#pum#prev(0) : exists("b:dotfiles_prose_mode") ? "\<C-o>g\<Up>"   : "\<Up>"
    inoremap <silent><expr> <C-Space> coc#refresh()

    nmap <silent> [g <Plug>(coc-diagnostic-prev)
    nmap <silent> ]g <Plug>(coc-diagnostic-next)

    nmap <silent> <space>gd <Plug>(coc-definition)
    nmap <silent> <space>gD <Plug>(coc-declaration)
    nmap <silent> <space>gt <Plug>(coc-type-definition)
    nmap <silent> <space>gi <Plug>(coc-implementation)
    nmap <silent> <space>gr <Plug>(coc-references)
    nmap <silent> <F2>      <Plug>(coc-rename)
    nmap <silent> <A-CR>    <Plug>(coc-codeaction-line)
    xmap <silent> <A-CR>    <Plug>(coc-codeaction-selected)
    nmap <silent> <A-d>     <Plug>(coc-diagnostic-info)

    nnoremap <silent> <space>K <Cmd>call CocActionAsync('doHover')<CR>
    nnoremap <silent> <space>s <Cmd>call CocActionAsync('showSignatureHelp')<CR>
    inoremap <silent> <F1>     <Cmd>call CocActionAsync('showSignatureHelp')<CR>

    nnoremap <silent> <space>l <Cmd>CocList<CR>
    nnoremap <silent> <space>d <Cmd>CocList --auto-preview diagnostics<CR>
    nnoremap <silent> <space>c <Cmd>CocList commands<CR>
    nnoremap <silent> <space>o <Cmd>CocList --auto-preview outline<CR>
    nnoremap <silent> <space>w <Cmd>CocList --interactive symbols<CR>
    nnoremap <silent> <space>e <Cmd>CocList extensions<CR>
    nnoremap <silent> <space>h <Cmd>CocPrev<CR>
    nnoremap <silent> <space>k <Cmd>CocPrev<CR>
    nnoremap <silent> <space>l <Cmd>CocNext<CR>
    nnoremap <silent> <space>j <Cmd>CocNext<CR>
    nnoremap <silent> <space>p <Cmd>CocListResume<CR>

    nmap <silent><expr> K  get(g:,'dotfiles_vimspector_active') ? "<Plug>VimspectorBalloonEval" : <SID>coc_buf_supports('hover') ? "<space>K" : "K"
    nmap <silent><expr> gd <SID>coc_buf_supports('definition')  ? "<space>gd" : "gd"
    nmap <silent><expr> gD <SID>coc_buf_supports('declaration') ? "<space>gD" : "gD"
    nmap <silent><expr> gr <SID>coc_buf_supports('reference')   ? "<space>gr" : "gr"

    function! s:jump_in_out_float_win() abort
      if !has('nvim') | return | endif
      let floats = coc#float#get_float_win_list()
      if empty(floats) | return | endif
      " This logic can be improved, but I think that in the most common case by
      " a huge margin (jumping in and out of the hover window) it is enough.
      if index(floats, win_getid()) >= 0
        wincmd p
      else
        call win_gotoid(floats[0])
      endif
    endfunction
    nnoremap <silent> <leader>j <Cmd>call <SID>jump_in_out_float_win()<CR>

    " Text objects!
    xmap if <Plug>(coc-funcobj-i)
    omap if <Plug>(coc-funcobj-i)
    xmap af <Plug>(coc-funcobj-a)
    omap af <Plug>(coc-funcobj-a)
    xmap iC <Plug>(coc-classobj-i)
    omap iC <Plug>(coc-classobj-i)
    xmap aC <Plug>(coc-classobj-a)
    omap aC <Plug>(coc-classobj-a)
  " }}}

  " CocFormat {{{
    function! s:CocFormat(range, line1, line2) abort
      if a:range == 0
        if !s:coc_buf_supports('format') | return | endif
        call CocAction('format')
      else
        if !s:coc_buf_supports('formatRange') | return | endif
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
  " Note that the real priorities range from signPriority to signPriority+4
  " <https://github.com/neoclide/coc.nvim/blob/70f11e074f45bc1bed1c17e3b0c2cf687f5582b6/src/diagnostic/buffer.ts#L257>
  let g:coc_user_config['diagnostic.signPriority'] = 20
  let g:coc_user_config['suggest.floatEnable'] = v:false
  let g:coc_user_config['suggest.enableFloat'] = v:false
  let g:coc_user_config['suggest.noselect'] = v:true
  let g:coc_user_config['inlayHint.enable'] = v:false
  let g:coc_user_config['workspace.progressTarget'] = 'statusline'
  let g:coc_user_config['coc.preferences.maxFileSize'] = '1MB'
  " On Neovim, the UltiSnips snippets loader has to spawn a subprocess for the
  " Python rplugin provider, even if no snippets in its format are found.
  let g:coc_user_config['snippets.ultisnips.enable'] = v:false
  let g:coc_user_config['signature.target'] = 'echo'
  let g:coc_user_config['dialog.rounded'] = v:false
  let g:coc_user_config['dialog.floatHighlight'] = 'CocFloating'
  let g:coc_user_config['dialog.floatBorderHighlight'] = 'CocFloating'
  let g:coc_user_config['list.selectedSignText'] = '> '
  let g:coc_disable_transparent_cursor = v:true
  " let g:coc_enable_locationlist = v:true
  " let g:coc_user_config['coc.preferences.useQuickfixForLocations'] = v:true
  let g:coc_user_config['workspace.rootPatterns'] = ['.vim', '.git', '.hg']

  augroup dotfiles_coc
    autocmd!
    " Bring back the <Esc> key for doing normal-mode edits.
    " <https://github.com/neoclide/coc.nvim/blob/bbaa1d5d1ff3cbd9d26bb37cfda1a990494c4043/autoload/coc/dialog.vim#L158-L160>
    autocmd User CocOpenFloatPrompt imap <buffer><silent><nowait> <Esc> <Esc>
    autocmd User CocOpenFloatPrompt imap <buffer><silent> <C-c> <Esc><Esc>
    autocmd User CocOpenFloatPrompt nmap <buffer><silent> <C-c> <Esc>
  augroup END

  let g:coc_user_config['colors.filetypes'] = ['*']
  let g:coc_user_config['semanticTokens.filetypes'] = ['*']
  let g:coc_default_semantic_highlight_groups = 0

  runtime! dotfiles/coc-languages/*.vim

  let g:coc_global_extensions = get(g:, 'coc_global_extensions', [])
  call extend(g:coc_global_extensions, keys(g:dotfiles_coc_extensions))

endif  " }}}


if dotplug#has('vimspector')  " {{{

  " <https://github.com/puremourning/vimspector/blob/ebeebc121423a5ab9a31c996f9881880b658c644/README.md#changing-the-default-signs>
  let s:vimspector_signs = {
  \ 'BP':            { 'prio': 30,  'text': 'o ', 'numhl': 0 },
  \ 'BPCond':        { 'prio': 30,  'text': 'o?', 'numhl': 0 },
  \ 'BPLog':         { 'prio': 30,  'text': 'o!', 'numhl': 0 },
  \ 'BPDisabled':    { 'prio': 30,  'text': 'ox', 'numhl': 0 },
  \ 'PC':            { 'prio': 200, 'text': ' >', 'numhl': 1 },
  \ 'PCBP':          { 'prio': 200, 'text': 'o>', 'numhl': 1 },
  \ 'CurrentThread': { 'prio': 200, 'text': '> ', 'numhl': 1 },
  \ 'CurrentFrame':  { 'prio': 200, 'text': '> ', 'numhl': 1 },
  \}

  let g:vimspector_sign_priority = {}
  for [s:sign_name, s:sign_conf] in items(s:vimspector_signs)
    let s:sign_name = 'vimspector'.s:sign_name
    let g:vimspector_sign_priority[s:sign_name] = s:sign_conf.prio
    call sign_define(s:sign_name, {
    \ 'text':   get(s:sign_conf, 'text', ''),
    \ 'texthl': get(s:sign_conf, 'texthl', 1) ? s:sign_name : '',
    \ 'numhl':  get(s:sign_conf, 'numhl',  0) ? s:sign_name : '',
    \})
  endfor

  augroup dotfiles_vimspector
    autocmd!
    let g:dotfiles_vimspector_active = 0
    autocmd User VimspectorUICreated  let g:dotfiles_vimspector_active = 1
    autocmd User VimspectorDebugEnded let g:dotfiles_vimspector_active = 0
  augroup END

  " <https://github.com/puremourning/vimspector/#mappings>
  " <https://developer.chrome.com/docs/devtools/shortcuts/#sources>
  nmap <silent> <A-'> <Plug>VimspectorStepOver
  nmap <silent> <A-;> <Plug>VimspectorStepInto
  nmap <silent> <A-:> <Plug>VimspectorStepOut
  nmap <silent> <A-S-;> <Plug>VimspectorStepOut
  nmap <silent> <A-.> <Plug>VimspectorDownFrame
  nmap <silent> <A-,> <Plug>VimspectorUpFrame
  nmap <silent> <A-b> <Plug>VimspectorToggleBreakpoint
  nmap <silent> <A-p> <Plug>VimspectorPause
  nmap <silent> <A-c> <Plug>VimspectorContinue
  nmap <silent> <A-r> <Plug>VimspectorRunToCursor

  command! -bar DbgStart    call vimspector#Launch()
  command! -bar DbgClose    call vimspector#Reset({'interactive': v:true})
  command! -bar DbgStop     call vimspector#Stop()
  command! -bar DbgRestart  call vimspector#Restart()
  command! -bar DbgBreak    call vimspector#SetLineBreakpoint(expand('%'), line('.'), {})
  command! -bar DbgBreakDel call vimspector#ClearLineBreakpoint(expand('%'), line('.'))
  command! -nargs=? DbgBreakFunc call vimspector#AddFunctionBreakpoint(!empty(<q-args>) ? <q-args> : expand('<cexpr>'))
  command! -bar DbgBreakClearAll call vimspector#ClearBreakpoints()
  command! -nargs=1 -complete=custom,vimspector#CompleteExpr DbgBreakIf   call vimspector#SetLineBreakpoint(expand('%'), line('.'), {'condition': <q-args>})
  command! -nargs=1 -complete=custom,vimspector#CompleteExpr DbgBreakHit  call vimspector#SetLineBreakpoint(expand('%'), line('.'), {'hitCondition': <q-args>})
  command! -nargs=1 -complete=custom,vimspector#CompleteExpr DbgBreakLog  call vimspector#SetLineBreakpoint(expand('%'), line('.'), {'logMessage': <q-args>})
  command! -nargs=1 -complete=custom,vimspector#CompleteExpr DbgEval      call vimspector#Evaluate(<q-args>)
  command! -nargs=1 -complete=custom,vimspector#CompleteExpr DbgWatch     call vimspector#AddWatch(<q-args>)
  command! -bar DbgStartLua lua require('osv').launch({ host = '127.0.0.1', port = 8086, blocking = true })

  let g:vimspector_configurations = {}
  let g:vimspector_adapters = {}

  let g:vimspector_adapters['multi-session'] = {
  \ 'host': '${host:localhost}',
  \ 'port': '${port}',
  \}

  let g:vimspector_configurations['Remote Attach'] = {
  \ 'autoselect': v:false,
  \ 'adapter': 'multi-session',
  \ 'configuration': {
  \   'request': 'attach',
  \ },
  \}

  runtime! dotfiles/vimspector/*.vim

endif  " }}}
