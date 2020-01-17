" <leader> is comma
let mapleader = ','

" allow moving cursor just after the last chraracter of the line
set virtualedit=onemore

set foldmethod=marker

" use line C-style comments instead of block ones (/* ... */)
set commentstring=//%s


" Indentination {{{

  function SetIndent(expandtab, shiftwidth)
    let &l:expandtab = a:expandtab
    let &l:shiftwidth = str2nr(a:shiftwidth)
    let &l:tabstop = &shiftwidth
    let &l:softtabstop = &shiftwidth
  endfunction
  command -nargs=1 Indent call SetIndent(1, <q-args>)
  command -nargs=1 IndentTabs call SetIndent(0, <q-args>)

  " use 2 spaces for indentination
  set expandtab shiftwidth=2 tabstop=2 softtabstop=2
  " round indents to multiple of shiftwidth when using shift (< and >) commands
  set shiftround

  let g:indentLine_char = "\u2502"
  let g:indentLine_first_char = g:indentLine_char
  let g:indentLine_showFirstIndentLevel = 1
  let g:indentLine_fileTypeExclude = ['text', 'help', 'tutor', 'man']

  let g:detectindent_preferred_indent = 2
  let g:detectindent_preferred_expandtab = 1
  " let g:detectindent_verbosity = 0

  augroup vimrc-detect-indent
    autocmd!
    autocmd FileType * if empty(&bt) | DetectIndent | endif
  augroup END

" }}}


" Invisible characters {{{
  set list
  let &listchars = "tab:\u2192 ,extends:>,precedes:<,eol:\u00ac,trail:\u00b7"
  let &showbreak = '>'
" }}}


" Cursor and Scrolling {{{

  set number
  set relativenumber
  set cursorline

  " remember cursor position
  augroup vimrc-editing-remember-cursor-position
    autocmd!
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exec "normal! g`\"" | endif
  augroup END

" }}}


" Wrapping {{{
  set nowrap
  set colorcolumn=80,100,120
" }}}


" Mappings {{{

  " stay in the Visual mode when using shift commands
  xnoremap < <gv
  xnoremap > >gv

  " 2 mappings for quick prototyping: duplicate this line and comment it out
  nmap <silent> <leader>] m'yygccp`'j
  nmap <silent> <leader>[ m'yygccP`'k

  command! -nargs=+ -complete=command PutOutput execute 'put =execute(' . escape(string(<q-args>), '|"') . ')'

  " Clipboard {{{
    " ,c is easier to type than "+ because it doesn't require pressing Shift
    noremap <leader>c "+
    " these 3 mappings are equivalent to Ctrl+C, Ctrl+V, and Ctrl+X in GUI
    " editors (hence the names)
    " noremap <leader>cc "+y
    " noremap <leader>cv "+gP
    " noremap <leader>cV "+gp
    " noremap <leader>cx "+d
  " }}}

  " make the default Vim mappings more consistent
  " https://www.reddit.com/r/vim/comments/dgbr9l/mappings_i_would_change_for_more_consistent_vim/
  nnoremap U <C-r>
  nnoremap Y y$

" }}}


" Search {{{

  " ignore case if the pattern doesn't contain uppercase characters (use '\C'
  " anywhere in pattern to override these two settings)
  set ignorecase smartcase

  nnoremap \ <Cmd>nohlsearch<CR>

  let g:indexed_search_center = 1

  " search inside a visual selection
  xnoremap / <Esc>/\%><C-R>=line("'<")-1<CR>l\%<<C-R>=line("'>")+1<CR>l
  xnoremap ? <Esc>?\%><C-R>=line("'<")-1<CR>l\%<<C-R>=line("'>")+1<CR>l

  " * and # in the Visual mode will search the selected text
  function! s:VisualStarSearch(search_cmd)
    let l:tmp = @"
    normal! gvy
    let @/ = '\V' . substitute(escape(@", a:search_cmd . '\'), '\n', '\\n', 'g')
    let @" = l:tmp
  endfunction
  " HACK: my mappings are added on VimEnter to override mappings from the
  " vim-indexed-search plugin
  augroup vimrc-editing-visual-star-search
    autocmd!
    autocmd VimEnter *
      \ xmap * :<C-u>call <SID>VisualStarSearch('/')<CR>n
      \|xmap # :<C-u>call <SID>VisualStarSearch('?')<CR>N
  augroup END

" }}}


" Replace {{{

  " show the effects of the :substitute command incrementally, as you type
  " (works similar to 'incsearch')
  set inccommand=nosplit

  " quick insertion of the substitution command
  nnoremap gs :%s///g<Left><Left><Left>
  xnoremap gs :s///g<Left><Left><Left>
  nnoremap gss :%s///g<Left><Left>
  xnoremap gss :s///g<Left><Left>

" }}}


" Formatting {{{

  " don't insert a comment after hitting 'o' or 'O' in the Normal mode
  augroup vimrc-editing-formatting
    autocmd!
    autocmd FileType * set formatoptions-=o
  augroup END

" }}}


" plugins {{{
  let g:delimitMate_expand_space = 1
  let g:delimitMate_expand_cr = 1

  let g:surround_{char2nr('*')} = "**\r**"

  let g:pencil#wrapModeDefault = 'soft'
  let g:pencil#conceallevel = 0
  let g:pencil#cursorwrap = 0

  xmap <leader>ga <Plug>(LiveEasyAlign)
  nmap <leader>ga <Plug>(LiveEasyAlign)
" }}}

" language-specific settings {{{

  let g:rust_recommended_style = 0

  let g:haskell_conceal = 0
  let g:haskell_conceal_enumerations = 0
  let g:haskell_multiline_strings = 1

" }}}
