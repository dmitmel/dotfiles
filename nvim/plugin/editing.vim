" <https://github.com/neovim/neovim/commit/6a7c904648827ec145fe02b314768453e2bbf4fe>
" <https://github.com/vim/vim/commit/957cf67d50516ba98716f59c9e1cb6412ec1535d>
let s:has_cmd_mappings = has('patch-8.2.1978') || has('nvim-0.3.0')

" HACK: This has to be one of my coolest hacks. The |<Cmd>| pseudo-key can be
" emulated in older versions of Vim simply by prepending code to the mapping to
" re-enter the previous mode. I create a mapping called `<SID>:` that should be
" used in place of |<Cmd>|, which appropriately handles execution of the command
" depending on the current mode. It is defined with |<SID>| and not |<Plug>| to
" allow using it from non-recursive mappings -- see |:map-script|. The only
" downside of my hack is that it is tricky to make it work well in the Insert
" mode, but that is addressed by the function `s:Cmd(...)`, which can be used in
" an <expr> mapping and works in ALL modes.
if s:has_cmd_mappings
  noremap  <SID>: <Cmd>
  inoremap <SID>: <Cmd>
  function! s:Cmd(cmd) abort
    return "\<Cmd>" . a:cmd . "\<CR>"
  endfunction
else
  " <C-u> is still needed in the Normal mode to erase the entered |count|.
  nnoremap <SID>: :<C-u>
  " Strangely enough, the Operator mode Just Works(tm). Even the information
  " about the |forced-motion| is preserved after doing `:` in the Operator mode,
  " see <https://github.com/vim/vim/issues/3490> and
  " <https://github.com/vim/vim/commit/5976f8ff00efcb3e155a89346e44f2ad43d2405a>.
  onoremap <SID>: :<C-u>
  " The main culprit: the Visual mode.
  xnoremap <SID>: :<C-u>exe'norm!gv'<bar>
  " It gets a lil bit tricky in the Select mode because we first need to switch
  " to the Visual mode with <C-g>, then re-enter it in the command-line and go
  " back to the Select mode from Visual with <C-g>.
  snoremap <SID>: <C-g>:<C-u>exe"norm!gv<C-g>"<bar>
  " NOTE: <C-o> causes the statusline to flicker! `s:Cmd` is better suited for
  " mappings that must work in the Insert mode!!! |i_CTRL-R_=| is required to
  " execute code or normal-mode commands, and theoretically, it is possible
  " to replace this mapping with something like `<C-r>=execute(input())<CR>`,
  " but in practice that makes it too slow.
  inoremap <SID>: <C-o>:<C-u>

  let s:cmd_payload = {
  \ 'n':                          ":\<C-u>call".expand('<SID>')."exec_cmd()\<CR>",
  \ 'v':             ":\<C-u>exe'norm!gv'|call".expand('<SID>')."exec_cmd()\<CR>",
  \ 's': "\<C-g>:\<C-u>exe'norm!gv\<C-g>'|call".expand('<SID>')."exec_cmd()\<CR>",
  \ 'i':                              "\<C-r>=".expand('<SID>')."exec_cmd()\<CR>",
  \ 't':  "\<C-\>\<C-n>:\<C-u>startinsert|call".expand('<SID>')."exec_cmd()\<CR>",
  \ }

  for s:alias in ['Vv', "\<C-v>v", 'Ss', "\<C-s>s", 'Ri', 'ci']
    let s:cmd_payload[s:alias[0]] = s:cmd_payload[s:alias[1]]
  endfor

  " Execute the provided command as-is after evaluating an <expr> mapping.
  function! s:Cmd(cmd) abort
    let s:queued_cmd = a:cmd
    return s:cmd_payload[mode()]
  endfunction

  " Note that this function is not marked with |abort|, both |:execute| and
  " |:unlet| should be allowed to fail
  function! s:exec_cmd()
    execute s:queued_cmd
    unlet   s:queued_cmd
    return  ''
  endfunction
endif

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
  " the case only for buffers without a filetype AND text files because most
  " ftplugins already define reasonable indentation settings.
  set smartindent
  " <Tab> inserts `shiftwidth` number spaces in front of a line, <BS> deletes
  " `shiftwidth` number spaces in front of a line.
  set smarttab
  " Use 2 spaces for indentination by default.
  set expandtab shiftwidth=2
  " When tabs are used though, give them the width of 4 (the influence of @2767mr).
  set tabstop=4
  " A negative number here tells Vim to use the value of `shiftwidth` for this option.
  set softtabstop=-1
  " Round indents to the multiple of shiftwidth when using shift (< and >) commands.
  set shiftround

  function! s:indent_cmd(use_tabs, arg, mods) abort
    if empty(a:arg) || a:arg ==# '?'
      if a:mods =~# '\<verbose\>'
        verbose set expandtab? shiftwidth? tabstop? softtabstop?
      else
        echo printf('set %set sw=%d ts=%d sts=%d', &l:et ? '' : 'no', &l:sw, &l:ts, &l:sts)
      endif
    else
      let width          = +(a:arg)
      let &l:expandtab   = !a:use_tabs
      let &l:shiftwidth  = width
      let &l:tabstop     = width
      let &l:softtabstop = -1
    endif
  endfunction
  command! -nargs=? -bar Indent      call s:indent_cmd(0, <q-args>, <q-mods>)
  command! -nargs=? -bar IndentTabs  call s:indent_cmd(1, <q-args>, <q-mods>)
  command! -nargs=0 -bar IndentReset setlocal expandtab< shiftwidth< tabstop< softtabstop<

  let g:indentLine_char = '│'
  let g:indentLine_first_char = g:indentLine_char
  let g:indentLine_showFirstIndentLevel = 1
  let g:indentLine_fileTypeExclude = ['text', 'help', 'tutor', 'man']
  let g:indentLine_bufTypeExclude = ['terminal', 'nofile']
  let g:indentLine_defaultGroup = 'IndentLine'
  let g:indent_blankline_show_trailing_blankline_indent = v:false
  let g:indent_blankline_show_current_context = v:true

  if dotplug#has('indentLine')
    " Nothing here, no further configuration is necessary for this plugin.
  elseif has('nvim-0.5.0')
    lua dotfiles.sane_indentline.setup()

    function! s:indent_lines_set(global, status) abort
      let dict = a:global ? g: : b:
      let status = a:status is# 'toggle' ? !get(dict, 'indentLine_enabled', 1) : a:status
      let dict['indentLine_enabled'] = status
      redraw!
    endfunction

    command! -bar -bang IndentLinesEnable  call s:indent_lines_set(<bang>0, 1)
    command! -bar -bang IndentLinesDisable call s:indent_lines_set(<bang>0, 0)
    command! -bar -bang IndentLinesToggle  call s:indent_lines_set(<bang>0, 'toggle')
    execute dotutils#cmd_alias('IL', 'IndentLinesToggle')

    "
  elseif has('patch-8.2.5066') || has('nvim-0.8.0')
    " <https://www.reddit.com/r/neovim/comments/17aponn/i_feel_like_leadmultispace_deserves_more_attention/>
    " <https://github.com/gravndal/shiftwidth_leadmultispace.nvim/blob/6f524bb6b2e21215d0c35553d09d826c65f97062/plugin/shiftwidth_leadmultispace.lua>
    function! s:update_leadmultispace() abort
      exe "setlocal listchars+=leadmultispace:\u2502" . repeat('\ ', shiftwidth() - 1)
    endfunction

    augroup dotfiles_indent
      autocmd!
      autocmd OptionSet shiftwidth,tabstop call s:update_leadmultispace()
      autocmd BufEnter *                   call s:update_leadmultispace()
    augroup END
  endif

  " NOTE: This is my very own custom Vim motion!!!
  " <https://vim.fandom.com/wiki/Creating_new_text_objects>
  noremap <script><silent> ( <SID>:call dotfiles#indent_motion#run(1)<CR>
  noremap <script><silent> ) <SID>:call dotfiles#indent_motion#run(0)<CR>
  " Don't pollute the Select mode.
  sunmap (
  sunmap )

" }}}


" Invisible characters {{{
  set list
  let &listchars = "tab:→ ,extends:>,precedes:<,eol:¬,trail:·,nbsp:␣"
  let &showbreak = '>'
  set display+=uhex
" }}}


" Cursor and Scrolling {{{
  set number relativenumber cursorline

  " This little snippet is based on |last-position-jump| from vimdocs and these:
  " <https://github.com/farmergreg/vim-lastplace/blob/e58cb0df716d3c88605ae49db5c4741db8b48aa9/plugin/vim-lastplace.vim>
  " <https://github.com/vim/vim/blob/v9.1.1406/runtime/defaults.vim#L100-L112>
  " <https://stackoverflow.com/questions/7894330/preserve-last-editing-position-in-vim>
  " <https://github.com/neovim/neovim/issues/16339>
  function! s:restore_cursor_pos() abort
    if !exists('b:did_restore_cursor_pos')
      let b:did_restore_cursor_pos = 1  " Fix for <https://github.com/farmergreg/vim-lastplace/issues/28>
      if index(['gitcommit', 'gitrebase', 'svn', 'hgcommit', 'xxd'], &filetype) < 0 &&
      \  index(['quickfix', 'nofile', 'help', 'terminal'], &buftype) < 0 &&
      \  1 <= line("'\"") && line("'\"") <= line('$')  " Check that the remembered position is valid
        execute 'normal! g`"zvzz'
      endif
    endif
  endfunction

  augroup dotfiles_remember_cursor_pos
    autocmd!
    " |BufWinEnter| is used instead of |BufReadPost| because:
    " 1. It makes `normal! zz` work for files supplied in |argument-list| when
    "    starting Vim from the command-line.
    " 2. It is triggered after FileType and after modelines are processed, so
    "    the actual filetype is known for sure.
    autocmd BufWinEnter * unsilent call s:restore_cursor_pos()
  augroup END
" }}}


" Wrapping {{{
  set nowrap          " By default, don't wrap lines longer than the window width permits, use horizontal scroll.
  set textwidth=80    " I use `textwidth` only for wrapping prose with `gw`, code wrapping is
  set colorcolumn=+1  " handled by formatters. Additionally, highlight the column at `textwidth+1`.
  set linebreak       " When wrapping, break lines only on `breakat` characters (also called "soft wrapping").
  set breakindent     " The wrapped text will be offset to the right with the width of the indent.
  set sidescroll=1    " Basically, smooth horizontal scrolling.

  " If the last line is wrapped, but does not fit into the window completely, display @@@ at the end.
  set display+=lastline
  " Same, but for the first line, if it does not fit completely, draw it partially and show <<< at the start.
  if exists('+smoothscroll') | set smoothscroll | endif

  " Swap `[hjkl]` and `g[hjkl]` keys when `wrap` is on.
  for s:key in ['j', 'k', '0', '$', '<Up>', '<Down>', '<Home>', '<End>']
    exe printf('noremap <expr>  %s &wrap ? "g%s" : "%s"', s:key, s:key, s:key)
    exe printf('noremap <expr> g%s &wrap ? "%s" : "g%s"', s:key, s:key, s:key)
    exe 'sunmap  '.s:key
    exe 'sunmap g'.s:key
  endfor

  " My final attempt at untangling the mess that are the <Up> and <Down> keys.
  for s:key in ['<Up>', '<Down>']
    " `./completion.vim` might remap <Up> and <Down> before `./editing.vim` runs,
    " so make the wrapped <Up/Down> keys available as <Plug>dotfiles<Up/Down>,
    " which `./completion.vim` can use.
    exe printf('inoremap <silent><expr> <Plug>dotfiles%s &wrap ? <SID>Cmd("normal! g%s") : "%s"',
          \ s:key, s:key, s:key)
    if empty(maparg(s:key, 'i'))
      exe 'imap' s:key '<Plug>dotfiles'.s:key
    endif
  endfor
" }}}


" Mappings {{{

  " stay in the Visual mode when using shift commands
  xnoremap < <gv
  xnoremap > >gv

  let s:comment_out_cmd = ''
  if dotplug#has('tcomment_vim')
    let s:comment_out_cmd = 'TComment!'   " the ! means to always comment out the line
  elseif dotplug#has('vim-commentary')
    let s:comment_out_cmd = 'Commentary'  " vim-commentary does not have this capability
  endif

  if !empty(s:comment_out_cmd)
    function! s:copy_and_comment_out(up) abort
      exe 'copy ' . (a:up ? '.' : '-')
      let pos = getcurpos()
      exe (a:up ? '-' : '+') . s:comment_out_cmd
      call setpos('.', pos)
    endfunction

    " Mappings for quick prototyping: duplicate this line and comment it out.
    nnoremap <silent> <leader>[ :<C-u>call <SID>copy_and_comment_out(0)<Bar>silent! call repeat#set('<leader>[')<CR>
    nnoremap <silent> <leader>] :<C-u>call <SID>copy_and_comment_out(1)<Bar>silent! call repeat#set('<leader>]')<CR>
  endif

  " A dead-simple implementation of the `[d` and `]d` mappings of LineJuggler
  " for duplicating lines back and forth.
  nnoremap <silent> [d :<C-u>copy-<C-r>=v:count+1<CR><Bar>silent! call repeat#set('[d')<CR>
  nnoremap <silent> ]d :<C-u>copy+<C-r>=v:count  <CR><Bar>silent! call repeat#set(']d')<CR>

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

  " Execute a macro on every line in a Visual selection. These were taken from
  " <https://github.com/neovim/neovim/blob/v0.11.0/runtime/lua/vim/_defaults.lua#L115-L130>
  xnoremap <silent><expr> @ (mode() ==# 'V' ? ':normal! @<C-r>=reg_recorded()<CR><CR>' : '@')
  xnoremap <silent><expr> Q (mode() ==# 'V' ? ':normal! @'.getcharstr().'<CR>' : 'Q')

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
  for [s:lhs, s:rhs] in items({
  \ 'h': 'zh', 'H': 'zH', 'l': 'zl', 'L': 'zL', 'Left': 'z<Left>', 'Right': 'z<Right>',
  \ 'j': '<C-e>', 'k': '<C-y>', 'J': '<C-d>', 'K': '<C-u>', 'Down': '<C-e>', 'Up': '<C-y>' })
    let s:lhs = '<M-' . s:lhs . '>'
    execute 'noremap' s:lhs s:rhs
    execute 'ounmap' s:lhs
    execute 'inoremap <silent><expr>' s:lhs '<SID>Cmd("normal! '.s:rhs.'")'
  endfor

  " Helpers to apply A/I to every line selected in Visual mode.
  xnoremap <expr> A (mode() ==# 'V' ? ':normal! A' : 'A')
  xnoremap <expr> I (mode() ==# 'V' ? ':normal! I' : 'I')

  " Break undo on CTRL-W and CTRL-U in the Insert mode.
  inoremap <C-u> <C-g>u<C-u>
  inoremap <C-w> <C-g>u<C-w>

  " Make <BS> and others work in the Select mode as expected. Otherwise, if <BS>
  " is pressed when a snippet placeholder is selected, the placeholder will be
  " deleted, but the editor will return to Normal mode, instead of Insert.
  " CTRL-G switches from Select mode to Visual, preserving the selected range.
  " Afterwards, `c` deletes the selected text and goes back into Insert mode.
  snoremap <silent> <BS>  <C-g>"_c
  snoremap <silent> <DEL> <C-g>"_c
  snoremap <silent> <C-h> <C-g>"_c
  snoremap          <C-r> <C-g>"_c<C-r>
  " Prevent coc.nvim from defining these for us:
  " <https://github.com/neoclide/coc.nvim/blob/c6cd3ed431a2fb4367971229198f1f1e40257bce/autoload/coc/snippet.vim#L23-L26>
  let g:coc_selectmode_mapping = 0

" }}}


" Keymap switcher {{{

  " Make sure that the `langmap` option doesn't affect mappings.
  set nolangremap

  nnoremap <leader>kk :<C-u>set keymap&<CR>
  nnoremap <leader>kr :<C-u>set keymap=russian-jcuken-custom<CR>
  nnoremap <leader>ku :<C-u>set keymap=ukrainian-jcuken-custom<CR>
  " imap     <A-k>      <C-o><leader>k

  nnoremap <C-o> :<C-u>DotfilesSwapKeymaps<CR>
  command! -nargs=0 DotfilesSwapKeymaps let [b:dotfiles_prev_keymap, &keymap] = [&keymap, get(b:, 'dotfiles_prev_keymap', '')]

" }}}


" Search {{{

  " ignore case if the pattern doesn't contain uppercase characters (use '\C'
  " anywhere in pattern to override these two settings)
  set ignorecase smartcase

  set hlsearch

  " \ is the inverse of / -- if the latter highlights search results, the
  " former executes :nohlsearch to turn the highlighting off.
  nnoremap <script><silent> \ <SID>:nohlsearch<CR>
  xnoremap <script><silent> \ <SID>:nohlsearch<CR>

  let g:indexed_search_center = 1

  let s:show_search_count_cmd = ''
  if dotplug#has('vim-indexed-search')
    let g:indexed_search_mappings = 0
    let s:show_search_count_cmd = 'ShowSearchIndex'
  elseif exists('*searchcount')
    " <https://github.com/neovim/neovim/commit/e498f265f46355ab782bfd87b6c85467da2845e3>
    command! -bar -bang ShowSearchIndex call dotfiles#search#show_count({'no_limits': <bang>0})
    let s:show_search_count_cmd = 'call dotfiles#search#show_count_async({})'
  endif

  " The following section is based on
  " <https://github.com/henrik/vim-indexed-search/blob/5af020bba084b699d0453f242d7d76711d64b1e3/plugin/indexed-search.vim#L94-L152>.
  function! s:after_search()
    if &foldopen =~# '\<all\>\|\<search\>'
      normal! zv
    endif
    if get(g:, 'indexed_search_center', 0)
      normal! zz
    endif
    execute s:show_search_count_cmd
    return ''
  endfunction

  noremap  <silent><script> <SID>after_search <SID>:call<SID>after_search()<CR>
  inoremap <silent>         <SID>after_search     <C-r>=<SID>after_search()<CR>

  " This mapping needs to be recursive, so that abbreviations in cmdline are
  " expanded when <CR> is pressed.
  cmap <expr> <CR> "\<CR>" . (getcmdtype() =~# '[/?]' ? "<SID>after_search" : '')

  noremap <script>       *   *<SID>after_search
  noremap <script>       #   #<SID>after_search
  noremap <script>       g*  g*<SID>after_search
  noremap <script>       g#  g#<SID>after_search
  noremap <script><expr> n  'Nn'[v:searchforward] . "<SID>after_search"
  noremap <script><expr> N  'nN'[v:searchforward] . "<SID>after_search"
  for s:key in ['*', '#', 'g*', 'g#', 'n', 'N']
    " Remove those from the Select and Operator modes.
    exe 'sunmap' s:key
    exe 'ounmap' s:key
  endfor

  " The built-in message that shows the number of search results should be
  " enabled only if a search counting plugin is not available at the moment.
  if has('patch-8.1.1270') || has('nvim-0.4.0')
    " <https://github.com/neovim/neovim/commit/777c2a25ce00f12b2d0dc26d594b1ba7ba10dcc6>
    if !empty(s:show_search_count_cmd)
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
  " These must be recursive to display the number of results after the search.
  xmap * :<C-u>call <SID>VisualStarSearch()<CR>/<CR>
  xmap # :<C-u>call <SID>VisualStarSearch()<CR>?<CR>

  " <https://vim.fandom.com/wiki/Searching_for_expressions_which_include_slashes#Searching_for_slash_as_normal_text>
  command! -nargs=+ Search        let @/ =       escape(<q-args>, '/') | normal! /<C-r>/<CR>
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

  " This operator was written mostly by referencing example code in |:map-operator|.
  function! s:substitute_operator(type) abort
    if empty(a:type)
      let s:substitute_operator_view = winsaveview()
      let &opfunc = expand('<SID>').'substitute_operator'
      return 'g@'
    endif

    let cmd = ''
    if a:type ==# 'line' && line("'[") == line('.') && line("']") == line('.')
      let cmd = ":\<C-u>.s/"
    elseif a:type ==# 'line' && line("'[") == 1 && line("']") == line('$')
      let cmd = ":\<C-u>%s/"
    elseif a:type ==# 'line'
      silent exe "normal! '[V']" | let cmd = ':s/'
    elseif a:type ==# 'block'
      silent exe "normal! `[\<C-v>`]" | let cmd = ':s/%V'
    elseif a:type ==# 'char'
      silent exe "normal! `[v`]" | let cmd = ':s/%V'
    else
      throw 'unrecognized argument: '.a:type
    endif

    if exists('s:substitute_operator_view')
      call winrestview(s:substitute_operator_view)
      unlet s:substitute_operator_view
    endif
    call feedkeys(cmd, 'n')  " 'n' - don't remap keys
  endfunction

  " The mnemonic is [g]o [s]ubstitute.
  nnoremap <expr> gs  <SID>substitute_operator('')
  " Substitute in the current line (`gsae` will substitute in the entire file).
  nnoremap <expr> gss <SID>substitute_operator('') . '_'
  " Substitute inside a Visual selection.
  xnoremap <expr> gs (mode() ==# 'V' ? ':s/' : ':s/\%V')

  " Repeat the last substitution and keep the flags.
  " Taken from <https://github.com/neovim/neovim/blob/v0.11.0/runtime/lua/vim/_defaults.lua#L108-L113>
  nnoremap & :&&<CR>

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
  execute dotutils#cmd_alias('Sp', 'SpellCheck!')

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


" Plugins {{{

  let g:delimitMate_expand_space = 1
  let g:delimitMate_expand_cr = 1
  " This conflicts with my <CR> mapping: <https://github.com/tpope/vim-eunuch/commit/c70b0ed50b5c0d806df012526104fc5342753749>
  let g:eunuch_no_maps = 1

  if !dotplug#has('delimitMate')
    inoremap <Plug>delimitMateCR <CR>
  endif

  let g:matchup_delim_noskips = 2
  let g:matchup_delim_nomids = 1
  let g:matchup_matchpref = {
  \ 'html': { 'tagnameonly': 1, 'nolists': 1 },
  \ 'xml': { 'tagnameonly': 1 },
  \ }

  augroup dotfiles_matchup
    autocmd!
    if has('nvim-0.11.0')
      " Since Neovim 0.11 the highlight groups in the statusline are now
      " combined with the statusline background, TODO
      " <https://github.com/neovim/neovim/commit/e049c6e4c08a141c94218672e770f86f91c27a11>
      autocmd User MatchupOffscreenEnter
      \ if exists('w:matchup_statusline') && &l:statusline is# w:matchup_statusline
      \|  let w:matchup_statusline = substitute(w:matchup_statusline, '%\@1<!%#Normal#', '%#StatusLine#', 'g')
      \|  let &l:statusline = w:matchup_statusline
      \|endif
    endif
  augroup END

  let g:surround_{char2nr('*')} = "**\r**"
  let g:surround_{char2nr('~')} = "~~\r~~"

  xmap <leader>a <Plug>(LiveEasyAlign)
  nmap <leader>a <Plug>(LiveEasyAlign)

  let g:sneak#prompt = 'sneak> '
  for s:key in ['f', 'F', 't', 'T']
    exe 'map' s:key '<Plug>Sneak_'.s:key
    exe 'sunmap' s:key
  endfor

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
    command HLT Inspect
    nmap <leader>hlt <Cmd>Inspect<CR>
    " Toggle treesitter highlighting in the buffer.
    nmap <leader>ht <Cmd>lua vim.treesitter[vim.b.ts_highlight and 'stop' or 'start']()<CR>
  else
    " Workaround for a select-mode mapping definition in:
    " <https://github.com/gerw/vim-HiLinkTrace/blob/64da6bf463362967876fdee19c6c8d7dd3d0bf0f/plugin/hilinks.vim#L45-L48>
    nmap <silent> <leader>hlt <Plug>HiLinkTrace
  endif

  let g:closetag_filetypes = 'html,xhtml,phtml,xslt'
  let g:closetag_xhtml_filetypes = 'xhtml,xslt'
  let g:closetag_filenames = ''
  let g:closetag_xhtml_filenames = ''

  let g:linediff_buffer_type = 'scratch'

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
  let g:python_highlight_all = 1

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
  let g:c_gnu = 1
  let g:cpp_attributes_highlight = 1
  let g:cpp_member_highlight = 1

  let g:lua_version = 5
  let g:lua_subversion = 1

  let g:vim_json_conceal = 0
  let g:javascript_plugin_jsdoc = 1
  let g:vim_jsx_pretty_disable_js = 1

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
