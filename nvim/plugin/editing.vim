" <https://github.com/neovim/neovim/commit/6a7c904648827ec145fe02b314768453e2bbf4fe>
" <https://github.com/vim/vim/commit/957cf67d50516ba98716f59c9e1cb6412ec1535d>
let s:has_cmd_mappings = has('patch-8.2.1978') || has('nvim-0.3.0')

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

if has('nvim-0.5.0') || has('patch-9.0.1921')
  set jumpoptions+=stack
endif
if has('nvim-0.10.2')
  set jumpoptions-=clean
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

  function! s:set_indent(use_tabs, cmd_arg, cmd_mods) abort
    if a:cmd_arg !=# '?'
      let prev_width = &l:expandtab ? shiftwidth() : &l:tabstop
      let width = empty(a:cmd_arg) ? prev_width : +(a:cmd_arg)
      let &l:expandtab   = !a:use_tabs
      let &l:shiftwidth  = width
      let &l:tabstop     = width
      let &l:softtabstop = width
    elseif a:cmd_mods =~# '\<verbose\>'
      verbose set expandtab? shiftwidth? tabstop? softtabstop?
    else
      echo printf('set %set sw=%d ts=%d sts=%d', &l:et ? '' : 'no', &l:sw, &l:ts, &l:sts)
    endif
  endfunction
  command! -nargs=? -bar Indent call s:set_indent(0, <q-args>, <q-mods>)
  command! -nargs=? -bar IndentTabs call s:set_indent(1, <q-args>, <q-mods>)
  command! -nargs=0 -bar IndentReset setlocal expandtab< shiftwidth< tabstop< softtabstop<

  let g:sleuth_automatic = 0
  function! DotfilesSleuth() abort
    if exists(':Sleuth') && get(b:, 'sleuth_automatic', 1)
      silent Sleuth
    endif
    " Sync shiftwidth, tabstop and softtabstop with each other.
    silent call s:set_indent(&l:expandtab, '', '')
  endfunction
  augroup dotfiles_sleuth_hack
    autocmd!
    autocmd FileType * nested call DotfilesSleuth()
  augroup END

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
    function! s:indent_lines_set(global, status) abort
      let dict = a:global ? g: : b:
      let status = a:status is# 'toggle' ? !get(dict, 'indentLine_enabled', 1) : a:status
      let dict['indentLine_enabled'] = status
      redraw!
    endfunction
    command! -bar -bang IndentLinesEnable  call s:indent_lines_set(<bang>0, 1)
    command! -bar -bang IndentLinesDisable call s:indent_lines_set(<bang>0, 0)
    command! -bar -bang IndentLinesToggle  call s:indent_lines_set(<bang>0, 'toggle')
  endif

  command! -bar -bang -range -nargs=? Unindent call dotfiles#indentation#unindent(<line1>, <line2>, str2nr(<q-args>))
  nnoremap <leader>< :Unindent<CR>
  xnoremap <leader>< :Unindent<CR>

  " NOTE: This is my very own custom Vim motion!!!
  " <https://vim.fandom.com/wiki/Creating_new_text_objects>
  noremap <expr> ( dotfiles#indentation#get_indent_motion(-1)
  noremap <expr> ) dotfiles#indentation#get_indent_motion(1)
  " <expr> mappings in Operator mode are not dot-repeatable.
  onoremap <silent> ( :<C-u>exe 'normal! V' . dotfiles#indentation#get_indent_motion(-1)<CR>
  onoremap <silent> ) :<C-u>exe 'normal! V' . dotfiles#indentation#get_indent_motion(1)<CR>
  " Don't pollute the Select mode.
  sunmap (
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

  let s:comment_out_cmd = ''
  if dotplug#has('tcomment_vim')
    let s:comment_out_cmd = 'TComment!'   " the ! means to always comment out the line
  elseif dotplug#has('vim-commentary')
    let s:comment_out_cmd = 'Commentary'  " vim-commentary does not have this capability"
  endif

  if !empty(s:comment_out_cmd)
    function! s:copy_and_comment_out(up) abort
      exe 'copy ' . (a:up ? '.' : '-')
      let pos = getcurpos()
      exe (a:up ? '-' : '+') . s:comment_out_cmd
      call setpos('.', pos)
      call repeat#set("\<Plug>dotfiles_copy_and_comment_" . (a:up ? 'above' : 'below'), v:count)
    endfunction

    nnoremap <Plug>dotfiles_copy_and_comment_above :call <SID>copy_and_comment_out(1)<CR>
    nnoremap <Plug>dotfiles_copy_and_comment_below :call <SID>copy_and_comment_out(0)<CR>

    nmap <silent> <leader>[ <Plug>dotfiles_copy_and_comment_below
    nmap <silent> <leader>] <Plug>dotfiles_copy_and_comment_above
  endif

  " A dead-simple implementation of the `[d` and `]d` mappings of LineJuggler
  " for duplicating lines back and forth.
  nnoremap <silent> [d :<C-u>copy-<C-r>=v:count+1<CR><CR>
  nnoremap <silent> ]d :<C-u>copy+<C-r>=v:count<CR><CR>

  " ,c is easier to type than "+ because it doesn't require pressing Shift
  " c stands for clipboard
  nnoremap <leader>c "+
  xnoremap <leader>c "+
  " these are for pasting the previous yanked text (the deletion commands don't
  " clobber the 0th register)
  nnoremap <leader>p "0
  xnoremap <leader>p "0

  " Make the default Vim mappings more consistent, see
  " <https://www.reddit.com/r/vim/comments/dgbr9l/mappings_i_would_change_for_more_consistent_vim/>
  " (this mapping has to be recursive because vim-repeat patches `<C-r>`)
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

  " Horizontal scroll (these mappings work in Normal, Visual and Select modes)
  " Alt+hjkl and Alt+Arrow  - scroll one column/row
  " Alt+Shift+hjkl          - scroll half a page
  for s:key in ['h', 'H', 'l', 'L', 'Left', 'Right']
    execute 'noremap <M-'.s:key.'> z'.(len(s:key) > 1 ? '<'.s:key.'>' : s:key)
    execute 'ounmap <M-'.s:key.'>'
  endfor
  " HACK: The first letter is the rhs of the mapping, the rest is the lhs. Do a backflip! :crazy:
  for s:key in ['ej', 'yk', 'dJ', 'uK', 'eDown', 'yUp']
    execute 'noremap <M-'.s:key[1:].'> <C-'.s:key[0].'>'
    execute 'ounmap <M-'.s:key[1:].'>'
  endfor

  " Helpers to apply A/I to every line selected in Visual mode.
  xnoremap A :normal! A
  xnoremap I :normal! I

  " Break undo on CTRL-W andd CTRL-U in the Insert mode.
  inoremap <C-u> <C-g>u<C-u>
  inoremap <C-w> <C-g>u<C-w>

  " My final attempt at untangling the mess that are the <Up> and <Down> keys.
  function! s:arrow_mapping(rhs) abort
    if get(b:, 'pencil_wrap_mode', 0) == 0
      return a:rhs   " No wrapping enabled
    elseif s:has_cmd_mappings
      return "\<Cmd>normal g" . a:rhs . "\<CR>"  " This does not make the statusline flicker
    else
      return "\<C-o>g" . a:rhs
    endif
  endfunction
  inoremap <expr> <Plug>dotfiles<Up>   <SID>arrow_mapping("<Up>")
  inoremap <expr> <Plug>dotfiles<Down> <SID>arrow_mapping("<Down>")

" }}}


" Keymap switcher {{{

  " Make sure that the `langmap` option doesn't affect mappings.
  set nolangremap

  nnoremap <leader>kk :set keymap&<CR>
  nnoremap <leader>kr :set keymap=russian-jcuken-custom<CR>
  nnoremap <leader>ku :set keymap=ukrainian-jcuken-custom<CR>
  imap     <A-k>      <C-o><leader>k

  nnoremap <C-o> :DotfilesSwapKeymaps<CR>
  command! -nargs=0 DotfilesSwapKeymaps let [b:dotfiles_prev_keymap, &keymap] = [&keymap, get(b:, 'dotfiles_prev_keymap', '')]

" }}}


" Search {{{

  " ignore case if the pattern doesn't contain uppercase characters (use '\C'
  " anywhere in pattern to override these two settings)
  set ignorecase smartcase

  set hlsearch

  " \ is the inverse of / -- if the latter highlights search results, the
  " former executes :nohlsearch to turn the highlighting off.
  if s:has_cmd_mappings
    " Everything's easier when you have <Cmd> -- these work instantly, silently
    " and without flicker.
    nnoremap \ <Cmd>noh<CR>
    xnoremap \ <Cmd>noh<CR>
  else
    " In legacy Vim's, situation's a bit more complex. Normal mode is trivial:
    nnoremap <silent> \ :noh<CR>
    " But Visual mode is where the flicker issue appears. `normal! gv` instead
    " of just `gv` at the end adresses the flicker problem.
    xnoremap <silent> \ :<C-u>noh<Bar>norm!gv<CR>
  endif

  let g:indexed_search_center = 1

  let s:searchcount_plugin_available = 1
  noremap <Plug>dotfiles_search_show_count <nop>
  if dotplug#has('vim-indexed-search')
    let g:indexed_search_mappings = 0
    nnoremap <Plug>dotfiles_search_show_count :ShowSearchIndex<CR>
    xnoremap <Plug>dotfiles_search_show_count :<C-u>ShowSearchIndex<CR>gv
  elseif exists('*searchcount')
    " <https://github.com/neovim/neovim/commit/e498f265f46355ab782bfd87b6c85467da2845e3>
    command! -bar -bang ShowSearchIndex call dotfiles#search#show_count_nowait({'no_limits': <bang>0})
    if s:has_cmd_mappings
      noremap <Plug>dotfiles_search_show_count <Cmd>call dotfiles#search#show_count({})<CR>
    else
      nnoremap <Plug>dotfiles_search_show_count :call dotfiles#search#show_count({})<CR>
      xnoremap <Plug>dotfiles_search_show_count :<C-u>call dotfiles#search#show_count({})<CR>gv
    endif
  else
    let s:searchcount_plugin_available = 0
  endif

  " The following section is based on
  " <https://github.com/henrik/vim-indexed-search/blob/5af020bba084b699d0453f242d7d76711d64b1e3/plugin/indexed-search.vim#L94-L152>.
  function! s:search_mapping_after()
    let fdo = has('folding') ? split(&foldopen, ',') : []
    return
    \ (index(fdo, 'all') >= 0 || index(fdo, 'search') >= 0 ? 'zv' : '') .
    \ (get(g:, 'indexed_search_center', 0) ? 'zz' : '') .
    \ "\<Plug>dotfiles_search_show_count"
  endfunction

  map  <expr> <Plug>dotfiles_search_after <SID>search_mapping_after()
  imap        <Plug>dotfiles_search_after <nop>

  cmap <expr> <CR> "\<CR>" . (getcmdtype() =~# '[/?]' ? "\<Plug>dotfiles_search_after" : '')
  " map  <expr> gd   "gd" . "\<Plug>dotfiles_search_after"
  " map  <expr> gD   "gD" . "\<Plug>dotfiles_search_after"
  map  <expr> *    "*"  . "\<Plug>dotfiles_search_after"
  map  <expr> #    "#"  . "\<Plug>dotfiles_search_after"
  map  <expr> g*   "g*" . "\<Plug>dotfiles_search_after"
  map  <expr> g#   "g#" . "\<Plug>dotfiles_search_after"
  map  <expr> n    "n"  . "\<Plug>dotfiles_search_after"
  map  <expr> N    "N"  . "\<Plug>dotfiles_search_after"
  " Remove those from the select mode.
  " sunmap gd
  " sunmap gD
  sunmap *
  sunmap #
  sunmap g*
  sunmap g#
  sunmap n
  sunmap N

  " The built-in message that shows the number of search results should be
  " enabled only if a search counting plugin is not available at the moment.
  if has('patch-8.1.1270') || has('nvim-0.4.0')
    " <https://github.com/neovim/neovim/commit/777c2a25ce00f12b2d0dc26d594b1ba7ba10dcc6>
    if s:searchcount_plugin_available
      set shortmess+=S
    else
      set shortmess-=S
    endif
  endif

  " search inside a visual selection
  xnoremap / <Esc>/\%V
  xnoremap ? <Esc>?\%V

  " * and # in the Visual mode will search the selected text
  function! s:VisualStarSearch() abort
    let tmp = @"
    try
      normal! gvy
      let @/ = dotutils#literal_regex(@")
    finally
      let @" = tmp
    endtry
  endfunction
  xmap * :<C-u>call <SID>VisualStarSearch()<CR>/<CR>
  xmap # :<C-u>call <SID>VisualStarSearch()<CR>?<CR>

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
    " NOTE: v:hlsearch can't be set inside of a function, see |function-search-undo|
    " NOTE: The command is returned as a string and executed later so that "No
    " match" errors don't display as a stack trace.
    return 'let v:hlsearch = 1 | '.a:loclist.'vimgrep '.dotutils#escape_and_wrap_regex(a:pattern).'gj %'
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
  xnoremap gs/ :s/\%V//g<Left><Left><Left>
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
  " This conflicts with my <CR> mapping: <https://github.com/tpope/vim-eunuch/commit/c70b0ed50b5c0d806df012526104fc5342753749>
  let g:eunuch_no_maps = 1

  let g:matchup_delim_noskips = 2
  let g:matchup_delim_nomids = 1
  let g:matchup_matchpref = {
  \ 'html': { 'tagnameonly': 1, 'nolists': 1 },
  \ 'xml': { 'tagnameonly': 1 },
  \ }

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

  " Remove the mappings that I won't use
  let g:tcomment_maps = 0

  if dotplug#has('tcomment_vim')
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
  endif

  " Prefer line C-style comments over block ones (/* ... */)
  set commentstring=//%s
  let g:tcomment#commentstring_c = '// %s'

  let g:tcomment_types = {
  \ 'asm':   '# %s',
  \ 'riscv': '# %s',
  \ }

  if has('nvim-0.9.0')
    nmap <silent> <leader>hlt <Cmd>Inspect<CR>
    command HLT Inspect
  else
    " Workaround for a select-mode mapping definition in:
    " <https://github.com/gerw/vim-HiLinkTrace/blob/64da6bf463362967876fdee19c6c8d7dd3d0bf0f/plugin/hilinks.vim#L45-L48>
    nmap <silent> <leader>hlt <Plug>HiLinkTrace
  endif

  let g:closetag_filetypes = 'html,xhtml,phtml,xslt'
  let g:closetag_xhtml_filetypes = 'xhtml,xslt'
  let g:closetag_filenames = ''
  let g:closetag_xhtml_filenames = ''

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

  let g:yats_host_keyword = 0         " for yats.vim as an external plugin
  let g:typescript_host_keyword = 0   " for yats.vim bundled with Vim/Nvim

  " <https://github.com/preservim/vim-markdown/blob/8f6cb3a6ca4e3b6bcda0730145a0b700f3481b51/ftplugin/markdown.vim#L770-L779>
  let g:vim_markdown_no_default_key_mappings = 1
  let g:vim_markdown_folding_disabled = 1

  let g:java_highlight_all = 1

  let g:c_no_bracket_error = 1
  let g:c_no_curly_error = 1

  let g:lua_version = 5
  let g:lua_subversion = 1

" }}}


" Script-writing and debugging {{{

  function! PutOutput(cmd) abort
    let output = ''
    silent! let output = dotfiles#sandboxed_execute#capture(a:cmd)
    call dotutils#open_scratch_preview_win({ 'title': a:cmd, 'text': output })
  endfunction
  command! -nargs=+ -complete=command PutOutput call PutOutput(<q-args>)

  " Same as typing commands literally, but creating local variables doesn't
  " pollute the global scope. Intended for interactive-mode debugging of
  " Vimscript.
  command! -nargs=+ -complete=command Execute try | call dotfiles#sandboxed_execute#(<q-args>) | catch | echoerr v:exception | endtry

  command! -nargs=+ -complete=command Timeit try | echo reltimefloat(dotfiles#sandboxed_execute#timeit(<q-args>)) | catch | echoerr v:exception | endtry

  function! Hex(n) abort
    return printf("%x", a:n)
  endfunction

  function! Bin(n) abort
    return printf("%b", a:n)
  endfunction

  function! Oct(n) abort
    return printf("%o", a:n)
  endfunction

" }}}
