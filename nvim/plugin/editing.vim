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

  augroup vimrc-indentlines-disable
    autocmd!
    autocmd TermOpen * IndentLinesDisable
    " <https://github.com/Yggdroot/indentLine/issues/315#issuecomment-734535963>
    autocmd VimEnter * if bufname('%') == '' | IndentLinesDisable | endif
  augroup END

  let g:detectindent_max_lines_to_analyse = 128
  let g:detectindent_check_comment_syntax = 1

  function s:DetectIndent()
    if !empty(&bt) | return | endif
    let g:detectindent_preferred_indent = &l:shiftwidth
    let g:detectindent_preferred_expandtab = &l:expandtab
    DetectIndent
  endfunction

  augroup vimrc-detect-indent
    autocmd!
    autocmd BufReadPost * call s:DetectIndent()
  augroup END

" }}}


" Invisible characters {{{
  set list
  let &listchars = "tab:\u2192 ,extends:>,precedes:<,eol:\u00ac,trail:\u00b7,nbsp:+"
  let &showbreak = '>'
  set display+=uhex
" }}}


" Cursor and Scrolling {{{
  set number relativenumber cursorline
  " remember cursor position
  augroup vimrc-editing-remember-cursor-position
    autocmd!
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exec "normal! g`\"" | endif
  augroup END
" }}}


" Wrapping {{{
  set nowrap colorcolumn=81,101,121
" }}}


" Mappings {{{

  " stay in the Visual mode when using shift commands
  xnoremap < <gv
  xnoremap > >gv

  " 2 mappings for quick prototyping: duplicate this line and comment it out
  nmap <silent> <leader>] m'yygccp`'j
  nmap <silent> <leader>[ m'yygccP`'k

  command! -nargs=+ -complete=command PutOutput execute 'put =execute(' . escape(string(<q-args>), '|"') . ')'

  " ,c is easier to type than "+ because it doesn't require pressing Shift
  noremap <leader>c "+

  " make the default Vim mappings more consistent
  " https://www.reddit.com/r/vim/comments/dgbr9l/mappings_i_would_change_for_more_consistent_vim/
  nmap U <C-r>
  nnoremap Y y$

  " <C-i> is treated as <tab> in terminals, so the original function of <C-i>
  " is inaccessible when something is bound to <tab> (buffer switching in my
  " case). <C-n> and <C-p> are basically useless because they are equivalent
  " to j and k respectively, but now they go to newer or older recorded cursor
  " position in the jump list.
  nnoremap <C-n> <C-i>
  nnoremap <C-p> <C-o>

  " Source of this trick: <https://youtu.be/bQfFvExpZDU?t=268>
  nnoremap Q gq

  " normal mode
  nnoremap <leader>dg :.diffget<CR>
  nnoremap <leader>dp :.diffput<CR>
  " visual mode
  xnoremap <leader>dg :diffget<CR>
  xnoremap <leader>dp :diffput<CR>

  " Horizontal scroll
  " Alt+hjkl and Alt+Arrow  - scroll one column/row
  " Alt+Shift+hjkl          - scroll half a page
  " normal mode
  nnoremap <M-h> zh
  nnoremap <M-H> zH
  nnoremap <M-Left> zh
  nnoremap <M-j> <C-e>
  nnoremap <M-J> <C-d>
  nnoremap <M-Down> <C-e>
  nnoremap <M-k> <C-y>
  nnoremap <M-K> <C-u>
  nnoremap <M-Up> <C-y>
  nnoremap <M-l> zl
  nnoremap <M-L> zL
  nnoremap <M-Right> zl
  " visual mode
  xnoremap <M-h> zh
  xnoremap <M-H> zH
  xnoremap <M-Left> zh
  xnoremap <M-j> <C-e>
  xnoremap <M-J> <C-d>
  xnoremap <M-Down> <C-e>
  xnoremap <M-k> <C-y>
  xnoremap <M-K> <C-u>
  xnoremap <M-Up> <C-y>
  xnoremap <M-l> zl
  xnoremap <M-L> zL
  xnoremap <M-Right> zl

" }}}


" Keymap switcher {{{

  nnoremap <leader>kk <Cmd>set keymap&<CR>
  nnoremap <leader>kr <Cmd>set keymap=russian-jcuken-custom<CR>
  nnoremap <leader>ku <Cmd>set keymap=ukrainian-jcuken-custom<CR>

  nnoremap <C-o> <Cmd>DotfilesSwapKeymaps<CR>
  let g:dotfiles_prev_keymap = &keymap
  command! -nargs=0 DotfilesSwapKeymaps let [g:dotfiles_prev_keymap, &keymap] = [&keymap, g:dotfiles_prev_keymap]

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
    let tmp = @"
    normal! y
    let @/ = '\V' . substitute(escape(@", a:search_cmd . '\'), '\n', '\\n', 'g')
    let @" = tmp
  endfunction
  " HACK: my mappings are added on VimEnter to override mappings from the
  " vim-indexed-search plugin
  augroup vimrc-editing-visual-star-search
    autocmd!
    autocmd VimEnter *
      \ xmap * <Cmd>call <SID>VisualStarSearch('/')<CR>n
      \|xmap # <Cmd>call <SID>VisualStarSearch('?')<CR>N
  augroup END

  " <https://vim.fandom.com/wiki/Searching_for_expressions_which_include_slashes#Searching_for_slash_as_normal_text>
  command! -nargs=+ Search let @/ = escape(<q-args>, '/') | normal /<C-R>/<CR>
  " <https://vim.fandom.com/wiki/Searching_for_expressions_which_include_slashes#Searching_for_all_characters_as_normal_text>
  command! -nargs=+ SearchLiteral let @/ = '\V'.escape(<q-args>, '/\') | normal /<C-R>/<CR>

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

  let g:sneak#prompt = 'sneak> '
  map f <Plug>Sneak_f
  map F <Plug>Sneak_F
  map t <Plug>Sneak_t
  map T <Plug>Sneak_T
  noremap <leader>s s
  noremap <leader>S S

  " Remove the mappings that I won't use
  let g:tcomment_maps = 0

  " Closely replicate the behavior of tpope/vim-commentary
  nmap <silent> gc  <Plug>TComment_gc
  nmap <silent> gcc <Plug>TComment_gcc
  nmap <silent> gC  <Plug>TComment_gcb
  " The default block commenting mapping refuses to work on a single line, as
  " a workaround I give it another empty one to work with.
  nmap <silent> gCC m'o<Esc>''<Plug>TComment_gcb+
  xnoremap <silent> gc :TCommentMaybeInline<CR>
  xnoremap <silent> gC :TCommentBlock<CR>
  " Make an alias for the comment text object
  omap <silent> gc ac

" }}}


" language-specific settings {{{

  let g:rust_recommended_style = 0

  let g:haskell_conceal = 0
  let g:haskell_conceal_enumerations = 0
  let g:haskell_multiline_strings = 1

  let g:vim_markdown_conceal = 0
  let g:vim_markdown_conceal_code_blocks = 0
  let g:vim_markdown_no_default_key_mappings = 0

  let g:vala_syntax_folding_enabled = 0

" }}}
