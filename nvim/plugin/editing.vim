" allow moving cursor just after the last chraracter of the line
set virtualedit=onemore

" Use the three-curly-brace markers ({{{ ... }}}) for folding.
set foldmethod=marker

" Make the backspace key work everywhere
set backspace=indent,eol,start

" Improve the behavior of the <Esc> key in regular Vim.
if !has('nvim') && &ttimeoutlen ==# -1
  set ttimeout ttimeoutlen=50
endif

" Makes the CTRL-A and CTRL-X commands compatible with Neovim in regular Vim.
set nrformats-=octal

" The Nvim docs say that this makes the jumpstack behave like the tagstack or
" like navigation history of a single tab in browsers.
if exists('+jumpoptions')
  set jumpoptions=stack
endif


" Indentination {{{

  set autoindent
  " <Tab> inserts `shiftwidth` number spaces in front of a line, <BS> deletes
  " `shiftwidth` number spaces in front of a line.
  set smarttab

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

  if g:dotfiles_sane_indentline_enable && has('nvim-0.5.0')
    lua require('dotfiles.sane_indentline')
    command! -bar -bang IndentLinesEnable
      \  if <bang>0
      \|   let g:indentLine_enabled = 1
      \| else
      \|   let b:indentLine_enabled = 1
      \| endif
      \| redraw!
    command! -bar -bang IndentLinesDisable
      \  if <bang>0
      \|   let g:indentLine_enabled = 0
      \| else
      \|   let b:indentLine_enabled = 0
      \| endif
      \| redraw!
    command! -bar -bang IndentLinesToggle
      \  if <bang>0
      \|   let g:indentLine_enabled = !get(g:, 'indentLine_enabled', 1)
      \| else
      \|   let b:indentLine_enabled = !get(b:, 'indentLine_enabled', 1)
      \| endif
      \| redraw!
  endif

  command! -bar -bang -range -nargs=? Unindent call dotfiles#indentation#unindent(<line1>, <line2>, str2nr(<q-args>))
  nnoremap <leader>< :Unindent<CR>
  xnoremap <leader>< :Unindent<CR>

  noremap <silent> <Plug>dotfiles_indent_motion_next <Cmd>call dotfiles#indentation#run_indent_motion(1)<CR>
  noremap <silent> <Plug>dotfiles_indent_motion_prev <Cmd>call dotfiles#indentation#run_indent_motion(-1)<CR>
  map ( <Plug>dotfiles_indent_motion_prev
  sunmap (
  map ) <Plug>dotfiles_indent_motion_next
  sunmap )

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
  function! s:restore_cursor_position() abort
    " Idea stolen from <https://github.com/farmergreg/vim-lastplace/blob/d522829d810f3254ca09da368a896c962d4a3d61/plugin/vim-lastplace.vim#L17-L19>:
    if index(['gitcommit', 'gitrebase', 'svn', 'hgcommit'], &filetype) >= 0
      return
    endif
    " Idea stolen from <https://github.com/farmergreg/vim-lastplace/blob/d522829d810f3254ca09da368a896c962d4a3d61/plugin/vim-lastplace.vim#L25-L27>:
    if index(['quickfix', 'nofile', 'help'], &buftype) >= 0
      return
    endif
    " I guess I could do some intelligent view centering simiarly to the plugin
    " (<https://github.com/farmergreg/vim-lastplace/blob/d522829d810f3254ca09da368a896c962d4a3d61/plugin/vim-lastplace.vim#L47-L70>),
    " but the truth is that it is complicated to account for stuff like folds,
    " and I've tried.
    if 1 <= line("'\"") && line("'\"") <= line('$')
      execute "normal! g`\"zz"
    endif
    silent! .foldopen
  endfunction
  augroup dotfiles_remember_cursor_position
    autocmd!
    " BufWinEnter is used instead of BufReadPost because apparently the latter
    " is called before windows are created when starting the editor, so when
    " opening a file supplied via the command line, `normal! zz` cease to work.
    autocmd BufWinEnter * unsilent call s:restore_cursor_position()
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
    let output = ''
    silent! let output = execute(a:cmd)
    call dotfiles#utils#open_scratch_preview_win({ 'title': a:cmd, 'text': output })
  endfunction
  command! -nargs=+ -complete=command PutOutput call PutOutput(<q-args>)

  " ,c is easier to type than "+ because it doesn't require pressing Shift
  nnoremap <leader>c "+
  xnoremap <leader>c "+

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

  xnoremap A :normal! A
  xnoremap I :normal! I

  " Break undo on CTRL-W andd CTRL-U in the Insert mode.
  inoremap <C-u> <C-g>u<C-u>
  inoremap <C-w> <C-g>u<C-w>

" }}}


" Keymap switcher {{{

  " Make sure that the `langmap` option doesn't affect mappings.
  set nolangremap

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

  set hlsearch
  nnoremap \ <Cmd>nohlsearch<CR>
  xnoremap \ <Cmd>nohlsearch<CR>

  let g:indexed_search_center = 1
  " If vim-indexed-search is installed, disable the built-in thing to show the
  " number of search results, otherwise enable it.
  if dotfiles#plugman#is_registered('vim-indexed-search')
    set shortmess+=S
  else
    set shortmess-=S
  endif

  " search inside a visual selection
  xnoremap / <Esc>/\%><C-r>=line("'<")-1<CR>l\%<<C-r>=line("'>")+1<CR>l
  xnoremap ? <Esc>?\%><C-r>=line("'<")-1<CR>l\%<<C-r>=line("'>")+1<CR>l

  " * and # in the Visual mode will search the selected text
  function! s:VisualStarSearch(search_cmd) abort
    let tmp = @"
    normal! y
    let @/ = '\V' . substitute(escape(@", a:search_cmd . '\'), '\n', '\\n', 'g')
    let @" = tmp
  endfunction
  " HACK: See `nvim/after/plugin/dotfiles/fixup.vim`
  xmap <Plug>dotfiles_VisualStarSearch_* <Cmd>call <SID>VisualStarSearch('/')<CR>n
  xmap <Plug>dotfiles_VisualStarSearch_# <Cmd>call <SID>VisualStarSearch('?')<CR>n
  xmap * <Plug>dotfiles_VisualStarSearch_*
  xmap # <Plug>dotfiles_VisualStarSearch_#
  xmap g* <Plug>dotfiles_VisualStarSearch_*
  xmap g# <Plug>dotfiles_VisualStarSearch_#

  " <https://vim.fandom.com/wiki/Searching_for_expressions_which_include_slashes#Searching_for_slash_as_normal_text>
  command! -nargs=+ Search let @/ = escape(<q-args>, '/') | normal! /<C-r>/<CR>
  " <https://vim.fandom.com/wiki/Searching_for_expressions_which_include_slashes#Searching_for_all_characters_as_normal_text>
  command! -nargs=+ SearchLiteral let @/ = '\V'.escape(<q-args>, '/\') | normal! /<C-r>/<CR>

  " Loads all search results for the current buffer into a quickfix/location
  " list. Based on <https://stackoverflow.com/a/1330556/12005228>, inspired by
  " <https://gist.github.com/romainl/f7e2e506dc4d7827004e4994f1be2df6>, better
  " than `vimgrep /pattern/ %`.
  function! s:CmdQfSearch(loclist, bang, pattern) abort
    let pattern = a:pattern
    if !empty(pattern)
      let @/ = pattern
      call histadd('search', pattern)
    else
      let pattern = @/
    endif
    let bang = a:bang ? '!' : ''

    let winnr = a:loclist ? winnr() : 0
    let bufnr = bufnr()
    let short_path = expand('%:.')
    let items = []
    let title = printf("Search%s /%s/ '%s'", bang, escape(pattern, '/'), short_path)

    let cursor_pos = getcurpos()
    " NOTE: :global doesn't position the cursor on the column where the search
    " pattern has been matched and won't call the command multiple times if a
    " line contains multiple matches, and so `col('.')` will return 1 on every
    " invocation. As such, column information is not saved.
    execute 'global'.bang."//call add(items, {'bufnr': bufnr, 'lnum': line('.'), 'text': getline('.')})"
    call setpos('.', cursor_pos)

    call dotfiles#utils#push_qf_list({'title': title, 'items': items, 'dotfiles_loclist_window': winnr})
  endfunction

  " NOTE: v:hlsearch can't be set inside of a function, see |function-search-undo|
  command! -bang -nargs=* Csearch call <SID>CmdQfSearch(0, <bang>0, <q-args>) | let v:hlsearch = 1
  command! -bang -nargs=* Lsearch call <SID>CmdQfSearch(1, <bang>0, <q-args>) | let v:hlsearch = 1

" }}}


" Replace {{{

  set incsearch
  " show the effects of the :substitute command incrementally, as you type
  " (works similar to 'incsearch')
  if exists('+inccommand')
    set inccommand=nosplit
  endif

  " quick insertion of the substitution command
  nnoremap gs/ :%s///g<Left><Left><Left>
  xnoremap gs/ :s///g<Left><Left><Left>
  nnoremap gss :%s///g<Left><Left>
  xnoremap gss :s///g<Left><Left>

" }}}


" Spell checking {{{

  function! SetSpellCheck(bang, lang) abort
    if a:bang
      let &l:spell = 0
    elseif empty(a:lang)
      let &l:spell = !&l:spell
    else
      let &l:spell = 1
      let &l:spelllang = a:lang
    endif
  endfunction
  command -nargs=? -bar -bang SpellCheck call SetSpellCheck(<bang>0, <q-args>)

" }}}


" Formatting {{{

  " See |fo-table|:
  " -o: don't insert a comment after hitting 'o' or 'O' in the Normal mode
  " +r: however, insert a comment after pressing Enter in the Insert mode
  " -t: don't auto-wrap regular code while typing
  " -c: don't auto-wrap comments while typing
  " +j: the J command should remove the comment leader when concating comments
  let s:formatoptions_changes = 'fo-=o fo+=r fo-=t fo-=c fo+=j'
  exe 'set' s:formatoptions_changes
  augroup dotfiles_formatoptions
    autocmd!
    exe 'autocmd FileType * setlocal' s:formatoptions_changes
  augroup END

  " Collapse multiple spaces into one when doing the `J` command.
  set nojoinspaces

" }}}


" plugins {{{

  let g:delimitMate_expand_space = 1
  let g:delimitMate_expand_cr = 1

  let g:matchup_delim_noskips = 2
  let g:matchup_delim_nomids = 1

  let g:surround_{char2nr('*')} = "**\r**"
  let g:surround_{char2nr('~')} = "~~\r~~"

  let g:pencil#wrapModeDefault = 'soft'
  let g:pencil#conceallevel = 0
  let g:pencil#cursorwrap = 0

  xmap <leader>a <Plug>(LiveEasyAlign)
  nmap <leader>a <Plug>(LiveEasyAlign)

  let g:sneak#prompt = 'sneak> '
  map f <Plug>Sneak_f
  map F <Plug>Sneak_F
  map t <Plug>Sneak_t
  map T <Plug>Sneak_T
  sunmap f
  sunmap F
  sunmap t
  sunmap T
  nnoremap <leader>s <Cmd>echoerr 'Please, use `cl` instead of `<leader>s`!'<CR>
  nnoremap <leader>S <Cmd>echoerr 'Please, use `cc` instead of `<leader>S`!'<CR>
  xnoremap <leader>s <Cmd>echoerr 'Please, use `c` instead of `<leader>s`!'<CR>
  xnoremap <leader>S <Cmd>echoerr 'Please, use `C` instead of `<leader>S`!'<CR>

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

  " Prefer line C-style comments over block ones (/* ... */)
  set commentstring=//%s
  let g:tcomment#commentstring_c = '// %s'

  let g:tcomment_types = {
  \ 'asm':   '# %s',
  \ 'riscv': '# %s',
  \ }

  " Workaround for a select-mode mapping definition in:
  " <https://github.com/gerw/vim-HiLinkTrace/blob/64da6bf463362967876fdee19c6c8d7dd3d0bf0f/plugin/hilinks.vim#L45-L48>
  nmap <silent> <leader>hlt <Plug>HiLinkTrace

" }}}


" language-specific settings {{{

  let g:rust_recommended_style = 0

  let g:vim_markdown_conceal = 0
  let g:vim_markdown_conceal_code_blocks = 0
  let g:vim_markdown_no_default_key_mappings = 0

  let g:vala_syntax_folding_enabled = 0

  let g:python_recommended_style = 0

  " Seems to be the closest one to SQLite. <https://www.sqlite.org/lang.html>
  let g:sql_type_default = 'sqlinformix'

  let g:yats_host_keyword = 0

" }}}
