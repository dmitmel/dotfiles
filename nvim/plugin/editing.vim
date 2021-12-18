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
" <https://vim.fandom.com/wiki/Indenting_source_code>

  set autoindent
  " `smartindent` is a "fallback" autoindentation mechanism which just uses
  " curly brackets and the words from `cinwords` for determining indentation
  " and is activated when `cindent` and `indentexpr` are not set. This will be
  " the case only for buffers without a filetype because most ftplugins already
  " define reasonable indentation settings, AND text files.
  set smartindent
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


  " Mappings for quick prototyping: duplicate this line and comment it out.
  " Explanation for how they work:
  " 1. First, a mark of the cursor position is recorded. This is done so that
  " we can later return back to the original position on the duplicated line.
  " 2. Then, a `:copy` command is inserted. In this instance it is the same as
  " doing `yyp` or `yyP`, but doesn't clobber the yank register.
  " 3. Afterwards the commenting command of the appropriate plugin is inserted.
  " It is done in a weird way using `:normal` so that the rest of the mapping
  " can be defined as non-recursive.
  " 4. Lastly, we return to the previously saved cursor position with CTRL-O
  " by popping from the jump list.
  " Also, please note that the number of spaces before the line continuation
  " backslashes matters here!

  nnoremap <silent> <Plug>dotfiles_dup_and_comment_up
  \ m':<C-u>copy.<Bar>exe "normal \<Plug>dotfiles_dup_and_comment_gcc"<CR><C-o>
  \:<C-u>silent! call repeat#set("\<Plug>dotfiles_dup_and_comment_up")<CR>

  nnoremap <silent> <Plug>dotfiles_dup_and_comment_down
  \ m':<C-u>copy-<Bar>exe "normal \<Plug>dotfiles_dup_and_comment_gcc"<CR><C-o>
  \:<C-u>silent! call repeat#set("\<Plug>dotfiles_dup_and_comment_down")<CR>

  if dotfiles#plugman#is_registered('tcomment_vim')
    " Tcomment allows us to comment out a line if it is a comment already
    nmap <silent> <Plug>dotfiles_dup_and_comment_gcc <Plug>TComment_Commentc
  elseif dotfiles#plugman#is_registered('vim-commentary')
    " vim-commentary does not
    nmap <silent> <Plug>dotfiles_dup_and_comment_gcc <Plug>CommentaryLine
  else
    nmap <silent> <Plug>dotfiles_dup_and_comment_gcc :<C-u>unsilent echo 'No commenting plugin found!'<CR>
  endif

  nmap <silent> <leader>[ <Plug>dotfiles_dup_and_comment_up
  nmap <silent> <leader>] <Plug>dotfiles_dup_and_comment_down


  " A dead-simple implementation of the `[d` and `]d` mappings of LineJuggler
  " for duplicating lines back and forth.
  nnoremap <silent> [d :<C-u>copy-<C-r>=v:count+1<CR><CR>
  nnoremap <silent> ]d :<C-u>copy+<C-r>=v:count<CR><CR>

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
  nnoremap <leader>dl <Plug>(linediff-operator)
  " visual mode
  xnoremap <leader>dg :diffget<CR>
  xnoremap <leader>dp :diffput<CR>
  xnoremap <leader>dl :Linediff<CR>

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
  " list. This comment used to say "better than `vimgrep /pattern/ %`", but this
  " is untrue since patch 8.2.3019: now vimgrep can record the end positions of
  " matches, while I have no easy way of doing that with what is given to me by
  " Vimscript. So, as they say, "if you can't beat 'em, join 'em", so there.
  " See also:
  " <https://stackoverflow.com/a/1330556/12005228>
  " <https://gist.github.com/romainl/f7e2e506dc4d7827004e4994f1be2df6>
  " <https://github.com/vim/vim/commit/6864efa59636ccede2af24e3f5f92d78d210d77b>
  function! s:cmd_qf_search(loclist, pattern) abort
    if !empty(a:pattern)
      let @/ = a:pattern
      call histadd('search', a:pattern)
    endif
    " I actually went to the trouble of finding in which exact patch flags were
    " added to vimgrep! See, patches that old weren't even checked-in into Git
    " properly (and, rather, pushed in batches), so I had to binary-search
    " through the archives on their FTP server.
    " <https://github.com/vim/vim/commit/05159a0c6a27a030c8497c5cf836977090f9e75d>.
    let flags = has('patch-7.0047') ? 'gj' : ''
    " NOTE: v:hlsearch can't be set inside of a function, see |function-search-undo|
    " NOTE: The command is returned as a string and executed later so that "No
    " match" errors don't display as a stack trace.
    return 'let v:hlsearch = 1 | '.a:loclist.'vimgrep '.dotfiles#utils#escape_and_wrap_regex(a:pattern).flags.' %'
  endfunction
  command! -nargs=* Csearch execute s:cmd_qf_search('',  <q-args>)
  command! -nargs=* Lsearch execute s:cmd_qf_search('l', <q-args>)

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
  " +n: recognize numbered lists (using `formatlistpat`) when wrapping text
  let s:formatoptions_changes = 'fo-=o fo+=r fo-=t fo-=c fo+=j fo+=n'
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
  " <https://github.com/vigoux/dotfiles/blob/eec3b72d2132a55f5cfeb6902f88b25106a33a36/neovim/.config/nvim/after/ftplugin/rust.vim#L6>
  let g:cargo_makeprg_params = 'build --message-format=short'

  let g:vim_markdown_conceal = 0
  let g:vim_markdown_conceal_code_blocks = 0
  let g:vim_markdown_no_default_key_mappings = 0

  let g:vala_syntax_folding_enabled = 0

  let g:python_recommended_style = 0

  " Seems to be the closest one to SQLite. <https://www.sqlite.org/lang.html>
  let g:sql_type_default = 'sqlinformix'

  let g:yats_host_keyword = 0

" }}}
