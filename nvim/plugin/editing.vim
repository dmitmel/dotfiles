" <leader> is comma
let mapleader = ','

" allow moving cursor just after the last chraracter of the line
set virtualedit=onemore

set foldmethod=marker

" use line C-style comments instead of block ones (/* ... */)
set commentstring=//%s


" Indentination {{{

  function! SetIndent(expandtab, shiftwidth) abort
    let &l:expandtab = a:expandtab
    let &l:shiftwidth = str2nr(a:shiftwidth)
    let &l:tabstop = &l:shiftwidth
    let &l:softtabstop = &l:shiftwidth
  endfunction
  command -nargs=1 -bar Indent call SetIndent(1, <q-args>)
  command -nargs=1 -bar IndentTabs call SetIndent(0, <q-args>)
  command -nargs=0 -bar IndentReset setlocal expandtab< shiftwidth< tabstop< softtabstop<

  " use 2 spaces for indentination
  set expandtab shiftwidth=2 tabstop=2 softtabstop=2
  " round indents to multiple of shiftwidth when using shift (< and >) commands
  set shiftround

  let g:indentLine_char = "\u2502"
  let g:indentLine_first_char = g:indentLine_char
  let g:indentLine_showFirstIndentLevel = 1
  let g:indentLine_fileTypeExclude = ['text', 'help', 'tutor', 'man']
  let g:indentLine_bufTypeExclude = ['terminal']
  let g:indentLine_bufNameExclude = ['^$', '^term://.*$']
  let g:indentLine_defaultGroup = 'IndentLine'
  let g:indent_blankline_show_trailing_blankline_indent = v:false

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
    autocmd BufReadPost *
      \ if line("'\"") > 1 && line("'\"") <= line("$")
      \|  exec "normal! g`\""
      \|endif
      \|silent! .foldopen
  augroup END
" }}}


" Wrapping {{{
  set nowrap colorcolumn=81,101,121 textwidth=79
" }}}


" Mappings {{{

  " stay in the Visual mode when using shift commands
  xnoremap < <gv
  xnoremap > >gv

  " 2 mappings for quick prototyping: duplicate this line and comment it out
  nmap <silent> <leader>] m'yygccp`'j
  nmap <silent> <leader>[ m'yygccP`'k

  function! PutOutput(cmd) abort
    let output = execute(a:cmd)
    execute 'noswapfile pedit' '+' . fnameescape('setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile') fnameescape('preview://' . a:cmd)
    wincmd P
    call setline(1, split(output, "\n"))
  endfunction
  command! -nargs=+ -complete=command PutOutput silent call PutOutput(<q-args>)

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

  " Repeat the last edit n times, taken from <https://gist.github.com/romainl/db725db7babc84a9a6436180cedee188>
  nnoremap . <Cmd>execute "normal!" repeat(".", v:count1)<CR>

  xnoremap A :normal! A
  xnoremap I :normal! I

" }}}


" Keymap switcher {{{

  nnoremap <leader>kk <Cmd>set keymap&<CR>
  nnoremap <leader>kr <Cmd>set keymap=russian-jcuken-custom<CR>
  nnoremap <leader>ku <Cmd>set keymap=ukrainian-jcuken-custom<CR>

  nnoremap <C-o> <Cmd>DotfilesSwapKeymaps<CR>
  command! -nargs=0 DotfilesSwapKeymaps let [b:dotfiles_prev_keymap, &keymap] = [&keymap, get(b:, 'dotfiles_prev_keymap', '')]

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
  function! s:VisualStarSearch(search_cmd) abort
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

  " -o: don't insert a comment after hitting 'o' or 'O' in the Normal mode
  " +r: however, insert a comment after pressing Enter in the Insert mode
  " -t: don't auto-wrap regular code while typing
  " -c: don't auto-wrap comments while typing
  augroup vimrc-editing-formatting
    autocmd!
    autocmd FileType *
      \ setlocal formatoptions-=o
      \|setlocal formatoptions+=r
      \|setlocal formatoptions-=t
      \|setlocal formatoptions-=c
  augroup END

" }}}


" plugins {{{

  let g:delimitMate_expand_space = 1
  let g:delimitMate_expand_cr = 1

  let g:surround_{char2nr('*')} = "**\r**"
  let g:surround_{char2nr('~')} = "~~\r~~"

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

  let g:tcomment#commentstring_c = '// %s'
  let g:tcomment_types = {
  \ 'asm':   '# %s',
  \ 'riscv': '# %s',
  \ }

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

  let g:python_recommended_style = 0

" }}}
