if !(dotplug#has('coc.nvim') && g:vim_ide == 1) | finish | endif

" NOTE: <Cmd> mappings are non-recursive and silent by default.

let g:coc_config_home = g:nvim_dotfiles_dir
let g:coc_disable_startup_warning = 1
" let g:coc_node_args = ['-r', expand('~/.config/yarn/global/node_modules/source-map-support/register'), '--nolazy', '--inspect']
let g:coc_user_config = {}
let g:coc_global_extensions = get(g:, 'coc_global_extensions', [])

let g:coc_snippet_next = '<Tab>'
let g:coc_snippet_prev = '<S-Tab>'

inoremap <silent><expr> <CR>      coc#pum#visible() ? coc#pum#confirm() : "\<Plug>delimitMateCR"
inoremap <silent><expr> <Tab>     coc#pum#visible() ? coc#pum#next(0)   : "\<Tab>"
inoremap <silent><expr> <S-Tab>   coc#pum#visible() ? coc#pum#prev(0)   : "\<S-Tab>"
inoremap <silent><expr> <Down>    coc#pum#visible() ? coc#pum#next(0)   : "\<Plug>dotfiles\<Down>"
inoremap <silent><expr> <Up>      coc#pum#visible() ? coc#pum#prev(0)   : "\<Plug>dotfiles\<Up>"
inoremap <silent><expr> <C-Space> coc#refresh()

nmap [g <Plug>(coc-diagnostic-prev)
nmap ]g <Plug>(coc-diagnostic-next)

nmap <space>gd <Plug>(coc-definition)
nmap <space>gD <Plug>(coc-declaration)
nmap <space>gt <Plug>(coc-type-definition)
nmap <space>gi <Plug>(coc-implementation)
nmap <space>gr <Plug>(coc-references)
nmap <F2>      <Plug>(coc-rename)
nmap <A-CR>    <Plug>(coc-codeaction-line)
xmap <A-CR>    <Plug>(coc-codeaction-selected)
nmap <A-d>     <Plug>(coc-diagnostic-info)

nmap <space>K <Cmd>call CocActionAsync('doHover')<CR>
nmap <space>s <Cmd>call CocActionAsync('showSignatureHelp')<CR>
nmap <space>l <Cmd>CocList<CR>
nmap <space>d <Cmd>CocList --auto-preview diagnostics<CR>
nmap <space>c <Cmd>CocList commands<CR>
nmap <space>o <Cmd>CocList --auto-preview outline<CR>
nmap <space>w <Cmd>CocList --interactive symbols<CR>
nmap <space>e <Cmd>CocList extensions<CR>
nmap <space>p <Cmd>CocListResume<CR>

function! s:coc_buf_supports(provider) abort
  return g:coc_service_initialized && CocAction('ensureDocument') && CocHasProvider(a:provider)
endfunction

nmap <expr> gd <SID>coc_buf_supports('definition')  ? "<Plug>(coc-definition)"  : "gd"
nmap <expr> gD <SID>coc_buf_supports('declaration') ? "<Plug>(coc-declaration)" : "gD"
nmap <expr> gr <SID>coc_buf_supports('reference')   ? "<Plug>(coc-references)"  : ""
imap <F1> <Cmd>call CocActionAsync('showSignatureHelp')<CR>

function! s:coc_hover_mapping() abort
  if get(g:, 'dotfiles_vimspector_active', 0)
    return "\<Plug>VimspectorBalloonEval"
  elseif s:coc_buf_supports('hover')
    return "\<Cmd>call CocActionAsync('doHover')\<CR>"
  else
    return 'K'
  endif
endfunction
nmap <expr> K <SID>coc_hover_mapping()

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
nmap <leader>j <Cmd>call <SID>jump_in_out_float_win()<CR>

" Text objects!
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap iC <Plug>(coc-classobj-i)
omap iC <Plug>(coc-classobj-i)
xmap aC <Plug>(coc-classobj-a)
omap aC <Plug>(coc-classobj-a)

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

" Stolen from <https://github.com/keanuplayz/dotfiles/blob/097aaf4ae3721b27c7fc341c6c7b99d78c7d9338/nvim/plugin/commands.vim#L1>
command! -nargs=0 -bar CocOrganizeImports call CocAction('organizeImport')

call dotutils#add_unique(g:coc_global_extensions, 'coc-snippets')

let g:coc_user_config['snippets.textmateSnippetsRoots'] =
\ [g:nvim_dotfiles_dir . '/snippets', g:dotfiles_dir . '/vscode/snippets']

" Show the cursor when in CocList
let g:coc_disable_transparent_cursor = v:true

let g:coc_user_config['colors.filetypes'] = ['*']
let g:coc_user_config['semanticTokens.filetypes'] = ['*']
let g:coc_default_semantic_highlight_groups = 0

" <https://github.com/neoclide/coc.nvim/blob/76ba8a29bf1342848b78a638065c93b38eaffdf3/src/diagnostic/manager.ts#L138-L149>
function! s:patch_coc_signs() abort
  for s:severity in ['Error', 'Warn', 'Info', 'Hint']
    call sign_define('Coc' . (s:severity ==# 'Warn' ? 'Warning' : s:severity), {
    \ 'texthl': 'DiagnosticSign'.s:severity,
    \ 'linehl': 'DiagnosticLine'.s:severity,
    \ 'numhl':  'DiagnosticLineNr'.s:severity,
    \ })
  endfor
endfunction

function! s:patch_coc_float_win() abort
  " Bring back the <Esc> key for doing normal-mode edits.
  " <https://github.com/neoclide/coc.nvim/blob/67b94293b8303d8b62f1ff0b43681630906c4377/autoload/coc/dialog.vim#L152-L154>
  imap <buffer> <Esc> <Esc>
  " Make <C-c> close the window immediately.
  imap <buffer> <C-c> <Esc><Esc>
  nmap <buffer> <C-c> <Esc>
endfunction

augroup dotfiles_coc
  autocmd!
  autocmd User CocNvimInit call s:patch_coc_signs()
  autocmd User CocOpenFloatPrompt call s:patch_coc_float_win()
augroup END

runtime! dotfiles/coc-languages/*.vim
