" The default mapping for clearing the screen is <CTRL-L> which I override to
" move around windows, and the :mode command is unintitively named at best.
" However, vim-sensible overrides the default mapping to also do :nohlsearch
" and :diffupdate. The first one doesn't exactly match the purpose of the key,
" but the latter may be useful.
" <https://github.com/tpope/vim-sensible/blob/2d9f34c09f548ed4df213389caa2882bfe56db58/plugin/sensible.vim#L35>
command! -bar ClearScreen exe 'mode' | if has('diff') | exe 'diffupdate' | endif

if dotplug#has('lazy.nvim')
  nnoremap <leader>l :<C-u>Lazy<CR>
else
  nnoremap <leader>l :<C-u>PlugStatus<CR>
endif

set wildmenu   " Enable completion in the command-line mode.

if has('patch-8.2.4325') || has('nvim-0.4.0')
  " This option used to be one of the selling points of Neovim.
  set wildoptions+=pum wildmode=longest,full
else
  " If the popup menu is not available, replicate the behavior of Zsh's
  " complist module under my configuration.
  " 1st <Tab> - complete till the longest common prefix (longest).
  " 2nd <Tab> - list the matches, but don't select or complete anything yet (list).
  " 3rd <Tab> - start the selection menu (i.e. wildmenu), select and complete the first match (full).
  set wildmode=longest,list,full
endif

if has('patch-8.2.4463') || has('nvim-0.9.0')
  set wildoptions+=fuzzy " Enable fuzzy matching in the cmdline completion menu
endif

" Disable showing completion-related messages in the bottom of the screen, such
" as "match X of Y", "The only match", "Pattern not found" etc.
set shortmess+=c

" Don't let the built-in completion mode (i_CTRL-N and i_CTRL-P) take results
" from included files. That is slow and imprecise, tags are much better for that.
set complete-=i

" Show the popup menu even if it contains only one item, and don't pre-select
" the first candidate in the list (also won't pre-insert the first completion).
set completeopt=menuone,noselect

if has('patch-9.1.0463') || has('nvim-0.11.0')
  set completeopt+=fuzzy   " Enable fuzzy matching in the popup completion menu
endif

" Set the maximum height of the completion menu, or the maximum number of items
" shown (by default the whole screen height will be used).
set pumheight=20

if exists('&pumwidth')
  " Set the minimum width of the completion menu if it is customizable (it used
  " to be hardcoded).
  set pumwidth=15
endif

if g:vim_ide == 0
  imap <silent><expr> <CR>    pumvisible() ? "\<C-y>" : "\<Plug>delimitMateCR"
  imap <silent><expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
  imap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
  imap <silent><expr> <Down>  pumvisible() ? "\<C-n>" : "\<Plug>dotfiles\<Down>"
  imap <silent><expr> <Up>    pumvisible() ? "\<C-p>" : "\<Plug>dotfiles\<Up>"
  imap <silent>     <C-Space> <C-x><C-o>
endif

" always show the sign column
set signcolumn=yes

" Show the currently typed editing command (or the size of the Visual-mode
" selected area) in the bottom right corner.
set showcmd

" enable bell everywhere
set belloff=

set title
if has('patch-8.2.2854') || has('nvim-0.5.0')
  set titlestring=%{%dotfiles#titlestring#get()%}
elseif exists('+titlestring')
  augroup dotfiles_titlestring
    autocmd!
    autocmd VimEnter,BufEnter * let &titlestring = dotfiles#titlestring#get()
  augroup END
endif

" Yes, I occasionally use mouse. Sometimes it is handy for switching windows/buffers.
set mouse=a
" This disables the (annoying) right-click popup menu in newer versions of Neovim.
set mousemodel=extend

" Crank up the command-line history size to the maximum!
set history=10000


" Buffers {{{

  set hidden

  " open diffs in vertical splits by default
  set diffopt+=vertical
  " The character used for filling deleted lines in diffs, will create a
  " crossed-out pattern. Idea taken from <https://github.com/sindrets/diffview.nvim#tips-and-faq>.
  set fillchars+=diff:╱
  if has('nvim-0.3.0')
    " This is a Neovim-only feature -- `msgsep` defines the border above the
    " output of shell commands issued with `:!`.
    set fillchars+=msgsep:▔
  else
    " Mirror the slick UI of Neovim in plain Vim.
    set fillchars+=vert:│
    set fillchars+=fold:·
    if has('patch-8.2.2524')
      set fillchars+=foldsep:│
    endif
  endif

  " Don't print filename and cursor position when switching between files.
  set shortmess+=F

  " buffer navigation {{{
    nnoremap <silent> <Tab>   :<C-u>bnext<CR>
    nnoremap <silent> <S-Tab> :<C-u>bprev<CR>
    nnoremap <silent> gb      :<C-u>buffer#<CR>
  " }}}

  " ask for confirmation when closing unsaved buffers
  set confirm

  command! -bar -bang -complete=buffer -nargs=? Bdelete  exe dotfiles#bufclose#cmd('bdelete<bang>',  <q-args>)
  command! -bar -bang -complete=buffer -nargs=? Bwipeout exe dotfiles#bufclose#cmd('bwipeout<bang>', <q-args>)

  function! s:close_buffer(b) abort
    if !empty(getcmdwintype()) || &buftype ==# 'help' || &buftype ==# 'quickfix' ||
    \  &previewwindow || dotutils#is_floating_window(0)
      return 'close'
    elseif &buftype ==# 'terminal'
      " Always wipe out the terminal buffers, so that they don't show up in the
      " jump history, and close the stopped ones with `:bwipeout!`.
      return a:b . (dotutils#is_terminal_running('%') ? 'wipeout' : 'wipeout!')
    else
      " NOTE: Don't use `:bwipeout` for closing normal buffers, it breaks
      " quickfix/loclists! When these lists are initialized, they also create
      " (but not load) buffers for all files referenced in the list, and <CR> in
      " a quickfix list expects the corresponding buffer to already exist.
      " Jumping to a list entry whose buffer has been wiped out fails with |E92|.
      return a:b . 'delete'
    endif
  endfunction

  " Delete the buffer without closing any windows.
  nnoremap <silent> <BS>  :<C-u>execute <SID>close_buffer('B')<CR>
  " Delete the buffer, but also close the window (that is, if it is not the last one).
  nnoremap <silent> <Del> :<C-u>execute <SID>close_buffer('b')<CR>

  augroup dotfiles_special_buffers
    autocmd!
    " How Neovim creates |:checkhealth| buffers:
    " <https://github.com/neovim/neovim/blob/master/runtime/lua/vim/health.lua>
    " <https://github.com/neovim/neovim/blob/master/runtime/ftplugin/checkhealth.lua>
    " <https://github.com/neovim/neovim/blob/master/runtime/ftplugin/checkhealth.vim>
    autocmd FileType checkhealth setlocal bufhidden=wipe
    " Customizations for the manpage viewer.
    " <https://github.com/neovim/neovim/blob/v0.11.1/runtime/lua/man.lua#L397-L405>
    autocmd FileType man if !empty(&buftype) | setlocal bufhidden=delete | endif
    " For `help` buffers it is important to check `buftype` because Vimdoc files
    " may be opened for editing as regular files, in which case having
    " `colorcolumn` and `signcolumn` enabled actually makes sense.
    autocmd FileType help if &buftype ==# 'help' | setlocal signcolumn=no colorcolumn= | endif
    autocmd FileType netrw,gitsigns-blame setlocal signcolumn=no colorcolumn= nolist
  augroup END

" }}}


" Windows {{{

  " Move between windows with CTRL+hjkl
  for s:key in ['h', 'j', 'k', 'l']
    execute 'nnoremap <C-'.s:key.'> <C-w>'.s:key
    execute 'xnoremap <C-'.s:key.'> <C-w>'.s:key
  endfor

  " Resize windows with CTRL+arrows
  nnoremap <silent> <C-Up>    :<C-u>resize +<C-r>=v:count1<CR><CR>
  nnoremap <silent> <C-Down>  :<C-u>resize -<C-r>=v:count1<CR><CR>
  nnoremap <silent> <C-Right> :<C-u>vertical resize +<C-r>=v:count1*2<CR><CR>
  nnoremap <silent> <C-Left>  :<C-u>vertical resize -<C-r>=v:count1*2<CR><CR>

  " switch to previous window
  nnoremap <C-\> <C-w>p
  xnoremap <C-\> <C-w>p

  nnoremap <silent> <M-BS> :<C-u>quit<CR>

  " Split-and-go-back. Particularly useful after go-to-definition.
  nnoremap <silent> <leader>v :<C-u>vsplit<bar>normal!<C-o><CR>

  " Make a split on the Z-axis or, more simply, open just the current buffer in a new tab.
  nnoremap <leader>t :<C-u>tab split<CR>
  nnoremap <leader>T :<C-u>tabclose<CR>

  nnoremap <C-t> :<C-u>tab split<CR>
  nnoremap <A-t> :<C-u>tabclose<CR>

  " Check if this floating windows are supported (or, rather,
  " `dotutils#is_floating_window` can detect them in any way).
  if exists('*win_gettype') || exists('*nvim_win_get_config')
    function! s:close_floating_popup(rhs) abort
      if dotutils#is_floating_window(0) && !exists('w:fzf_lua_preview')
        return "\<C-w>c"
      elseif exists('b:lsp_floating_preview') && nvim_win_is_valid(b:lsp_floating_preview)
        " Can't close a window within an |<expr>| mapping because of textlock.
        return "\<Cmd>call nvim_win_close(b:lsp_floating_preview, v:false)\<CR>"
      else
        return a:rhs
      endif
    endfunction

    nnoremap <expr> <Esc> <SID>close_floating_popup("\<Esc>")
    nnoremap <expr>   q   <SID>close_floating_popup("q")
  endif

" }}}


" Airline (statusline) {{{

  " Always show the statusline/tabline (even if there is only one window/tab).
  set laststatus=2 showtabline=2

  let g:airline_symbols = extend(get(g:, 'airline_symbols', {}), {
  \ 'readonly': 'RO',
  \ 'whitespace': '',
  \ 'colnr': ' :',
  \ 'linenr': ' :',
  \ 'maxlinenr': '',
  \ 'branch': '',
  \ 'notexists': ' [?]',
  \ 'executable': '',
  \ })

  let g:airline_mode_map = extend(get(g:, 'airline_mode_map', {}), {
  \ 'ic': 'INSERT COMPL',
  \ 'ix': 'INSERT COMPL',
  \ 'Rc': 'REPLACE COMP',
  \ 'Rx': 'REPLACE COMP',
  \ })

  " <https://github.com/vim-airline/vim-airline/issues/1779>
  let g:airline_highlighting_cache = 1
  " Disable definition of `<Plug>AirlineSelectTab` shortcuts. This is a
  " low-impact optimization. So, one day I was debugging significant lag
  " occuring while typing (or rather mashing keys in the Insert mode) with the
  " completion menu open. I narrowed it down to a function called `map_keys` in
  " vim-airline's tabline extension:
  " <https://github.com/vim-airline/vim-airline/blob/de73a219034eb0f94be0b50cc1f2414559816796/autoload/airline/extensions/tabline/buffers.vim#L195-L213>,
  " the profiler showed it and a few other tabline-related functions high in
  " the profile. I later realized that the lag was actually caused by a
  " `:redrawtabline` command I used for debugging cmp-buffer (I had a debug
  " display which would be drawn onto the tabline), but, after running the
  " profiler again, this function would show up high in the profiling results,
  " so I decided to keep the optimization because I don't use those maps anyway.
  let g:airline#extensions#tabline#buffer_idx_mode = 0

  " NOTE: `fzf` must come BEFORE `term`!
  let s:ext = ['quickfix', 'fzf', 'term', 'whitespace', 'wordcount', 'filesize', 'tabline']
  let s:has_hunks_provider = dotplug#has('vim-gitgutter') || dotplug#has('vim-signify') || dotplug#has('gitsigns.nvim')
  if s:has_hunks_provider              | call add(s:ext, 'hunks')                       | endif
  if dotplug#has('vim-fugitive')       | call extend(s:ext, ['branch', 'fugitiveline']) | endif
  if dotplug#has('coc.nvim')           | call extend(s:ext, ['coc', 'coclist'])         | endif
  if has('nvim-0.5') && g:vim_ide == 2 | call add(s:ext, 'nvimlsp')                     | endif
  if dotplug#has('snacks.nvim')        | call add(s:ext, 'snacks_picker')               | endif
  if dotplug#has('fzf-lua')            | call insert(s:ext, 'fzf_lua')                  | endif
  let g:airline_extensions = s:ext

  let g:airline_detect_iminsert = 1
  let g:airline#extensions#tabline#left_sep = ' '
  let g:airline#extensions#tabline#left_alt_sep = ''
  " This pattern never matches anything, found it in `:help /\_$`. This needs to
  " be done because airline by default hides all terminal buffers.
  let g:airline#extensions#tabline#ignore_bufadd_pat = '\_$.'

  augroup dotfiles_airline
    autocmd!
    " `showmode` shows the current mode in the cmdline area, `ruler` shows a
    " very primitive statusline with the current column and line number.
    autocmd User AirlineToggledOff set   showmode   ruler
    autocmd User AirlineToggledOn  set noshowmode noruler
  augroup END

" }}}


" FZF {{{
  if dotplug#has('fzf-lua')
    command! -bar Manpages    FzfLua manpages
    command! -bar Registers   FzfLua registers
    command! -bar Cfzf cclose|FzfLua quickfix
    command! -bar Lfzf lclose|FzfLua loclist
  else
    command! -bar -bang Manpages call dotfiles#fzf#manpage_search(<bang>0)
    command! -bar -bang Cfzf     call dotfiles#fzf#qflist_fuzzy(0, <bang>0)
    command! -bar -bang Lfzf     call dotfiles#fzf#qflist_fuzzy(1, <bang>0)
  endif

  nnoremap <silent> <F1>      :<C-u>Helptags<CR>
  nnoremap <silent> <leader>f :<C-u>Files<CR>
  nnoremap <silent> <leader>b :<C-u>Buffers<CR>
  nnoremap <silent> <leader>m :<C-u>Manpages<CR>
  nnoremap <silent> <C-/>     :<C-u>Lines<CR>

  if dotplug#has('fzf-lua')
    nnoremap <silent> z= <Cmd>FzfLua spell_suggest<CR>
  endif

  let $FZF_DEFAULT_OPTS = ''
    " Never show the separator between the prompt and the list
  let $FZF_DEFAULT_OPTS .= ' --no-separator'
  " Display the available/filtered/selected items numbers to the right of the prompt
  let $FZF_DEFAULT_OPTS .= ' --info=inline-right'
  " Set the scrollbar character.
  let $FZF_DEFAULT_OPTS .= ' --scrollbar=┃█'
  " The character used for gaps between multiline items. IMO the default '┈' is too distracting.
  let $FZF_DEFAULT_OPTS .= ' --gap-line=-'
  " Jump to the first entry whenever the query changes, taken from fzf(1).
  let $FZF_DEFAULT_OPTS .= ' --bind=change:first'
  " Highlight the current line similarly to how Vim highlights CursorLine.
  let $FZF_DEFAULT_OPTS .= ' --highlight-line'

  let g:fzf_layout = { 'down': '~40%', 'tmux': '60%,80%' }
  let g:fzf_vim = { 'preview_window': ['right:60%:border-left', 'ctrl-/'] }

  let g:fzf_colors = {
  \ 'fg':        ['fg', 'Normal'],
  \ 'bg':        ['bg', 'Normal'],
  \ 'hl':        ['fg', 'String'],
  \ 'fg+':       ['fg', 'CursorLine', 'Label'],
  \ 'bg+':       ['bg', 'CursorLine'],
  \ 'hl+':       ['fg', 'String'],
  \ 'gutter':    ['bg', 'LineNr', 'Normal'],
  \ 'pointer':   ['fg', 'Identifier'],
  \ 'marker':    ['fg', 'Keyword'],
  \ 'border':    ['fg', 'WinSeparator'],
  \ 'separator': ['fg', 'WinSeparator'],
  \ 'scrollbar': ['fg', 'WinSeparator'],
  \ 'header':    ['fg', 'Normal'],
  \ 'info':      ['fg', 'PmenuExtra'],
  \ 'spinner':   ['fg', 'String'],
  \ 'query':     ['fg', 'Normal'],
  \ 'prompt':    ['fg', 'Title'],
  \ 'nomatch':   ['fg', 'Comment'],
  \ }

  command! -bar -bang -nargs=0 FilesRuntime Files<bang> $VIMRUNTIME

  command! -bar -bang -nargs=? -complete=custom,dotplug#complete_plugin_names FilesPlugins
  \ if empty(<q-args>)
  \|  exe 'Files<bang>' fnameescape(g:dotplug#plugins_dir)
  \|elseif dotplug#has(<q-args>)
  \|  exe 'Files<bang>' fnameescape(dotplug#plugin_dir(<q-args>))
  \|else
  \|  echoerr 'Plugin not found: ' . string(<q-args>)
  \|endif

  nnoremap <silent> <leader>P :<C-u>FilesPlugins<CR>
  nnoremap <silent> <leader>R :<C-u>FilesRuntime<CR>
" }}}


if dotplug#has('snacks.nvim') " {{{
  function! SnacksPick(...) abort
    call luaeval('dotfiles.snacks_picker(_A, { '.join(a:000[1:], ' ').' })', get(a:000, 0, 'pickers'))
  endfunction

  function! SnacksPickerComplete(arg_lead, cmd_line, cursor_pos) abort
    return join(luaeval('vim.tbl_keys(Snacks.picker.sources)'), "\n")
  endfunction

  command! -nargs=* -complete=custom,SnacksPickerComplete SnacksPick call SnacksPick(<f-args>)

  if !dotplug#has('fzf-lua')
    " Command definitions in fzf.vim:
    " <https://github.com/junegunn/fzf.vim/blob/dc71692255b62d1f67dc55c8e51ab1aa467b1d46/plugin/fzf.vim#L47-L69>
    command! -bar Helptags SnacksPick help
    command! -bar Manpages SnacksPick man
    command! -bar Lines    SnacksPick grep_buffers
    command! -bar BLines   SnacksPick lines
    command! -bar Buffers  SnacksPick buffers
    command! -bar Colors   SnacksPick colorschemes
    command! -bar Marks    SnacksPick marks
    command! -bar Commands SnacksPick commands
    command! -bar Maps     SnacksPick keymaps

    command! -bar Cfzf cclose|SnacksPick qflist
    command! -bar Lfzf lclose|SnacksPick loclist

    command! -nargs=* Grep call v:lua.dotfiles.snacks_picker('grep', { 'search': <q-args> })

    " Based on:
    " <https://github.com/junegunn/fzf.vim/blob/dc71692255b62d1f67dc55c8e51ab1aa467b1d46/autoload/fzf/vim.vim#L414-L423>
    " <https://github.com/junegunn/fzf.vim/blob/dc71692255b62d1f67dc55c8e51ab1aa467b1d46/autoload/fzf/vim.vim#L403-L410>
    function! s:pick_files(arg) abort
      let slash = (has('win32') && !&shellslash) ? '\' : '/'
      if empty(a:arg)
        let dir = getcwd()
      elseif isdirectory(a:arg)
        let dir = a:arg
      else
        throw 'not a directory: ' . a:arg
      endif
      let short = pathshorten(fnamemodify(dir, ':~:.'))
      let short = empty(short) ? '.' : short
      let short .= dotutils#ends_with(short, slash) ? '' : slash
      call v:lua.dotfiles.snacks_picker('files', { 'dirs': [dir], 'prompt': short })
    endfunction
    command! -nargs=? -complete=dir Files call s:pick_files(<q-args>)
  endif
endif " }}}


" quickfix/location list {{{

  " vim-unimpaired provides these mappings, but they do not wrap around the
  " start/end of the lists.
  nmap [q <Plug>(qf_qf_previous)
  nmap ]q <Plug>(qf_qf_next)
  nmap [l <Plug>(qf_loc_previous)
  nmap ]l <Plug>(qf_loc_next)
  " Go to the quickfix list, or close the current list.
  nmap <expr>   Q   get(b:, 'qf_isLoc', 0) ? "\<Plug>(qf_loc_toggle)" : "\<Plug>(qf_qf_toggle)"
  " Go to the location list, or close the current list.
  nmap <expr> <C-q> get(b:, 'qf_isLoc', 1) ? "\<Plug>(qf_loc_toggle)" : "\<Plug>(qf_qf_toggle)"
  " Pick and jump using fzf!
  nnoremap <expr> <leader>z ":\<C-u>" . (get(b:, 'qf_isLoc', 0) ? 'L' : 'C') . "fzf\<CR>"

  " Enable nice mappings, like `o` to open and come back, `p` to preview and so on and so on.
  let g:qf_mapping_ack_style = 1
  " Filter entries based on both the file path and the text (see |:Keep| and |:Reject|).
  let g:qf_bufname_or_text = 2

" }}}


if dotplug#has('vim-dispatch')
  execute dotutils#cmd_alias('make', 'Make')
  nnoremap <F9> :<C-u>Make<CR>
else
  nnoremap <F9> :<C-u>make!<CR>
endif


function! s:run_file() abort
  if exists('b:runfileprg')
    return (b:runfileprg[0] ==# ':' ? b:runfileprg[1:] : '!' . b:runfileprg)
  else
    return '!' . expand('%:h') . '/' . expand('%:t')
  endif
endfunction
command! -bar -nargs=* Run execute s:run_file() . (!empty(<q-args>) ? ' ' : '') . <q-args>
nnoremap <F5> :<C-u><C-r>=<SID>run_file()<CR><CR>


if exists('*api_info')
  command! -bar -bang NvimApi call dotfiles#nvim_api_cheat_sheet#open()
endif


" Terminal {{{

  " Start a terminal with the default shell in the current window.
  if has('nvim')
    nnoremap ! :<C-u>terminal<CR>
  else
    nnoremap ! :<C-u>terminal ++curwin ++noclose<CR>
  endif

  function! s:fix_terminal_window() abort
    setlocal nolist nonumber norelativenumber colorcolumn= signcolumn=no
    " `virtualedit` used to be a global-only option
    if (has('patch-8.2.3227') || has('nvim-0.7.0')) | setlocal virtualedit=none | endif
    if dotplug#has('indentLine') | exe 'IndentLinesDisable' | endif
  endfunction

  augroup dotfiles_terminal
    autocmd!
    if has('nvim')
      autocmd TermOpen * call s:fix_terminal_window()
      autocmd TermOpen * startinsert
      " An elegant solution to <https://github.com/neovim/neovim/issues/5176> -
      " simply keep the user out of the terminal after its job has stopped! Once
      " the process within the terminal exits, I have the choice to close the
      " buffer either with <BS> or <Del>. Needs v0.4.0 for the `TermEnter`
      " autocommand and for `stopinsert` to be able to leave the TERMINAL mode[1].
      " [1]: <https://github.com/neovim/neovim/commit/d928b036dc2be8f043545c0d7e2a2b2285528aaa>
      if has('nvim-0.4.0')
        autocmd TermClose * if expand('<abuf>') == bufnr('%') | stopinsert | endif
        autocmd TermEnter * if !dotutils#is_terminal_running('%') | stopinsert | endif
      endif
    elseif exists('##TerminalWinOpen')
      autocmd TerminalWinOpen * call s:fix_terminal_window()
    endif
  augroup END

  " Disable the default autocommand which auto-closes terminal buffers started
  " without any explicit arguments, as it uses `:bdelete` to do its job, which
  " breaks the window layout. <https://github.com/neovim/neovim/pull/15440>
  if exists('#nvim_terminal#TermClose')
    autocmd! nvim_terminal TermClose *
  endif
  " They changed the naming scheme of built-in autocommands in v0.11.0:
  " <https://github.com/neovim/neovim/commit/09e01437c968be4c6e9f6bb3ac8811108c58008c>
  if exists('#nvim.terminal#TermClose')
    autocmd! nvim.terminal TermClose *
  endif

" }}}


if exists('*nvim_get_proc_children')
  function! s:all_proc_children(pid, arr) abort
    call add(a:arr, a:pid)
    call map(nvim_get_proc_children(a:pid), 's:all_proc_children(v:val, a:arr)')
    return a:arr
  endfunction

  function! s:list_editor_processes() abort
    let ps_columns = ['user', 'pid', 'pcpu', 'pmem', 'rss', 'etime', 'cmd']
    execute
    \ '!ps --forest --format' join(ps_columns, ',') join(s:all_proc_children(getpid(), []), ' ')
    \ '| numfmt --header=1 --field='.(index(ps_columns, 'rss') + 1).' --to=iec --from-unit=1024'
    \ '| column --table'
    \          '--table-columns-limit='.len(ps_columns)
    \          '--table-truncate='.(index(ps_columns, 'cmd') + 1)
    \          '--output-width='.(&columns - 1)
  endfunction

  command! -bar Process call s:list_editor_processes()
endif


" This is a fix for an ancient bug that exists ever since Neovim v0.3.1
" (introduced by this PR: <https://github.com/neovim/neovim/pull/8578>): when an
" hlgroup is linked to `Normal`, the cursor line/column background will not be
" drawn over it. Such linked groups occasionally appear in syntax files, and it
" looks super ugly:
" 1. <https://github.com/neovim/neovim/issues/9019>
" 2. <https://github.com/neovim/neovim/issues/35017>
" I work around this by simply finding all hlgroups linked to `Normal` and
" resetting them. I also assume that the syntax highlight groups start with a
" lowercase letter, as opposed to interface-related ones which are all
" capitalized, and only patch the former ones because sometimes it makes sense
" for UI hlgroups to be linked to `Normal`.
if has('nvim-0.3.1')
  if has('nvim-0.9.0')
    " In newer versions we can accelerate this process by using Lua and Nvim API
    function! s:patch_highlights() abort
      lua <<EOF
      for name, info in pairs(vim.api.nvim_get_hl(0, { link = true })) do
        if info.link == 'Normal' and name:match('^[a-z]') then
          vim.api.nvim_set_hl(0, name, {})
        end
      end
EOF
    endfunction
  else
    " Okay, so the fallback implementation is really jank, but it works well and
    " is pretty fast.
    function! s:patch_highlights() abort
      let lines = split(execute('highlight'), "\n")
      let idx = 0
      while 1
        " This function will find the first string in the array that matches the
        " given regexp, and is considerably faster than checking each string in
        " a loop in Vimscript. `\zs` and `\ze` are used because it does not
        " return the matched subgroups.
        let [name, idx, _, _] = matchstrpos(lines, '^\zs\l\w\+\ze\s\+xxx links to Normal$', idx)
        if idx < 0 | break | endif
        exe 'highlight! link' name 'NONE'
        let idx += 1
      endwhile
    endfunction
  endif

  let s:done_syntaxes = {}
  function! s:on_syntax(name) abort
    if !has_key(s:done_syntaxes, a:name)
      try
        call s:patch_highlights()
      catch /^Vim\%((\a\+)\)\=:E12:/
        " If the |'syntax'| option was set within a modeline, the |Syntax| event
        " will still get triggered, but the autocommands for it will run within
        " the |sandbox|, which causes stuff like |execute()| or |:highlight| to
        " fail with |E12|. I don't have a good solution for that right now.
      endtry
      let s:done_syntaxes[a:name] = 1
    endif
  endfunction

  function! s:on_colorscheme() abort
    let s:done_syntaxes = {}

    " The `Ignore` a built-in hlgroup that is used for concealed characters in
    " Vim Help files. In Nvim v0.10.0 it became linked to Normal in the C code:
    " <https://github.com/neovim/neovim/blob/v0.10.0/src/nvim/highlight_group.c#L203>.
    " I actually never knew this group even existed because it is always
    " concealed in the |:help| viewer, but this became a problem in Fzf-Lua's
    " |:Helptags| searcher.
    hi! link Ignore NONE

    call s:patch_highlights()
  endfunction

  augroup dotfiles_patch_highlights
    autocmd!
    autocmd Syntax * call s:on_syntax(expand('<amatch>'))
    autocmd Colorscheme,VimEnter * call s:on_colorscheme()
  augroup END
endif
