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
  if has('nvim')
    " This is a Neovim-only feature -- `msgsep` defines the border above the
    " output of shell commands issued with `:!`.
    set fillchars+=msgsep:▔
  else
    " Mirror the slick UI of Neovim in plain Vim.
    set fillchars+=vert:│
    set fillchars+=fold:·
    set fillchars+=foldsep:│
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

  function! s:is_floating() abort
    if exists('*win_gettype')
      return win_gettype() ==# 'popup'
    elseif exists('*nvim_win_get_config')
      return nvim_win_get_config(0).relative !=# ''
    else
      return 0
    endif
  endfunction

  function! s:close_buffer() abort
    if !empty(getcmdwintype()) || &buftype ==# 'help' || &buftype ==# 'quickfix' ||
    \  &previewwindow || &filetype ==# 'fugitive' || s:is_floating()
      close
    else
      Bdelete
    endif
  endfunction

  " NOTE: Don't use :Bwipeout! For example, it breaks qflist/loclist switching
  " because when these lists are loaded, they also create (but not load) buffers
  " for all of the mentioned files, and jumping to an entry in the list whose
  " buffer was wiped out fails with |E92|.
  nnoremap <silent> <BS>  :<C-u>call <SID>close_buffer()<CR>
  " Delete the buffer, but also close the window (that is, if it's not the last one).
  nnoremap <silent> <Del> :<C-u>bdelete<CR>

" }}}


" Windows {{{

  for s:key in ['h', 'j', 'k', 'l']
    for s:mode in ['n', 'x']
      execute s:mode.'noremap <C-'.s:key.'> <C-w>'.s:key
    endfor
  endfor

  " switch to previous window
  nnoremap <C-\> <C-w>p
  xnoremap <C-\> <C-w>p

  nnoremap <silent> <M-Backspace> :<C-u>quit<CR>

  " Split-and-go-back. Particularly useful after go-to-definition.
  nnoremap <leader>v :<C-u>vsplit<bar>normal!<C-o><CR>

  " Make a split on the Z-axis or, more simply, open just the current buffer in a new tab.
  nnoremap <leader>t :<C-u>tab split<CR>
  nnoremap <leader>T :<C-u>tabclose<CR>

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
  \ }

  function! s:FilesPlugins(bang, arg) abort
    let fzf_cmd = 'Files' . (a:bang ? '!' : '')
    if empty(a:arg)
      execute fzf_cmd fnameescape(g:dotplug#plugins_dir)
    elseif dotplug#has(a:arg)
      execute fzf_cmd fnameescape(dotplug#plugin_dir(a:arg))
    else
      echohl WarningMsg
      echomsg 'Plugin not found: ' . string(a:arg)
      echohl None
    endif
  endfunction

  command! -bar -bang -nargs=0 FilesRuntime Files<bang> $VIMRUNTIME
  command! -bar -bang -nargs=* -complete=custom,dotplug#complete_plugin_names FilesPlugins
  \ call s:FilesPlugins(<bang>0, <q-args>)

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
  nmap <expr> Q     get(b:, 'qf_isLoc', 0) ? "\<Plug>(qf_loc_toggle)" : "\<Plug>(qf_qf_toggle)"
  " Go to the location list, or close the current list.
  nmap <expr> <C-q> get(b:, 'qf_isLoc', 1) ? "\<Plug>(qf_loc_toggle)" : "\<Plug>(qf_qf_toggle)"
  " Jump again to the exact location of the currently selected error.
  nnoremap <leader>q :<C-u>cc<CR>zv
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
nnoremap <F5> :<C-r>=<SID>run_file()<CR><CR>


if exists('*api_info')
  command! -bar -bang NvimApi call dotfiles#nvim_api_cheat_sheet#open()
endif


augroup dotfiles_terminal
  autocmd!
  autocmd WinEnter * if &buftype == 'terminal' | startinsert | endif

  let s:fix_terminal_win = 'setlocal nolist nonumber norelativenumber colorcolumn= signcolumn=no'
  if has('patch-8.2.3227') || has('nvim-0.7.0')  " `virtualedit` used to be a global-only option
    let s:fix_terminal_win .= ' virtualedit=none'
  endif

  if has('nvim')
    autocmd TermOpen * execute s:fix_terminal_win
    autocmd TermOpen * startinsert
  elseif has('terminal')
    autocmd TerminalWinOpen * execute s:fix_terminal_win
    autocmd TerminalWinOpen * IndentLinesDisable
  endif
augroup END

if has('nvim')
  exe dotutils#cmd_alias('term', 'split<Bar>term')
endif
