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
  nnoremap <leader>l :<C-u>PlugDiff<CR>
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
let g:dotfiles_titlestring_user_host = $USER . '@' . substitute(hostname(), '\.local$', '', '')
function! s:titlestring() abort
  if &filetype ==# 'fzf' && exists('b:fzf')
    let str = "FZF %{get(b:fzf,'name','')}"
  else
    let str = '%F%m'
  endif
  return '%{g:dotfiles_titlestring_user_host}: ' . str . ' (%{v:progname})'
endfunction
if has('patch-8.2.2854') || has('nvim-0.5.0')
  let &titlestring = '%{%'.expand('<SID>').'titlestring()%}'
else
  let &titlestring = s:titlestring()
  augroup dotfiles_titlestring
    autocmd!
    autocmd BufEnter * let &titlestring = s:titlestring()
  augroup END
endif

" Yes, I occasionally use mouse. Sometimes it is handy for switching windows/buffers.
set mouse=a
" This disables the (annoying) right-click popup menu in newer versions of Neovim.
set mousemodel=extend

" Crank up the command-line history size to the maximum!
let &history = max([&history, 10000])


" Buffers {{{

  set hidden

  " open diffs in vertical splits by default
  set diffopt+=vertical

  " Don't print filename and cursor position when switching between files.
  set shortmess+=F

  " buffer navigation {{{
    nnoremap <silent> <Tab>   :<C-u>bnext<CR>
    nnoremap <silent> <S-Tab> :<C-u>bprev<CR>
    nnoremap <silent> gb      :<C-u>buffer#<CR>
  " }}}

  " ask for confirmation when closing unsaved buffers
  set confirm

  function! s:ConfirmBbye(bang, cmd) abort
    let result = a:bang ? 2 : dotutils#do_confirm()
    if result
      return a:cmd . (result == 2 ? '!' : '')
    else
      return ''
    endif
  endfunction
  command! -bar -bang ConfirmBdelete  execute s:ConfirmBbye(<bang>0, 'Bdelete')
  command! -bar -bang ConfirmBwipeout execute s:ConfirmBbye(<bang>0, 'Bwipeout')

  " NOTE: Don't use :Bwipeout! For example, it breaks qflist/loclist
  " switching because when these lists are loaded, they also create (but not
  " load) buffers for all of the mentioned files, and should a buffer be
  " deleted entirely, switching to that buffer starts to fail with E92.
  nnoremap <silent> <BS>  :<C-u>ConfirmBdelete<CR>
  nnoremap <silent> <Del> :<C-u>ConfirmBdelete<bar>quit<CR>

" }}}


" Windows {{{

  " Smooth horizontal scrolling, basically.
  set sidescroll=1

  " When `wrap` is on and the last line doesn't fit on the screen, display it
  " partially with @@@ at the end.
  set display+=lastline

  for s:key in ['h', 'j', 'k', 'l']
    for s:mode in ['n', 'x']
      execute s:mode.'noremap <C-'.s:key.'> <C-w>'.s:key
    endfor
  endfor

  " switch to previous window
  nnoremap <C-\> <C-w>p
  xnoremap <C-\> <C-w>p

  " Don't automatically make all windows the same size. Breaks the `:sbuffer`
  " command used for the preview window in CocList. TODO: investigate.
  " set noequalalways

  nnoremap <silent> <A-BS> :<C-u>quit<CR>

  " Split-and-go-back. Particularly useful after go-to-definition.
  nnoremap <leader>v <C-W>v<C-O>

  " Open just the current buffer in a new tab.
  nnoremap <leader>t :<C-u>tab split<CR>
  nnoremap <leader>T :<C-u>tabclose<CR>

" }}}


" Airline (statusline) {{{

  " Always show the statusline/tabline (even if there is only one window/tab).
  set laststatus=2 showtabline=2

  function! s:on_airline_toggled(is_on)
    let &g:showmode = !a:is_on
    let &g:ruler = !a:is_on
  endfunction
  augroup dotfiles_airline
    autocmd!
    autocmd User AirlineToggledOff call s:on_airline_toggled(0)
    autocmd User AirlineToggledOn  call s:on_airline_toggled(1)
  augroup END
  call s:on_airline_toggled(0)

  let g:airline_theme = 'dotfiles'
  let g:airline_symbols = {
    \ 'readonly': 'RO',
    \ 'whitespace': '',
    \ 'colnr': ' :',
    \ 'linenr': ' :',
    \ 'maxlinenr': ' ',
    \ 'branch': '',
    \ 'notexists': ' [?]',
    \ }
  let g:airline_mode_map = {
  \ 'ic': 'INSERT COMPL',
  \ 'ix': 'INSERT COMPL',
  \ 'Rc': 'REPLACE COMP',
  \ 'Rx': 'REPLACE COMP',
  \ }

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

  let g:airline_extensions = [
    \ 'quickfix',
    \ 'fzf',
    \ 'term',
    \ 'whitespace',
    \ 'wordcount',
    \ 'tabline',
    \ 'dotfiles_tweaks',
    \ 'dotfiles_filesize',
    \ ]
  if dotplug#has('vim-fugitive')
    call extend(g:airline_extensions, ['branch', 'fugitiveline'])
  endif
  if dotplug#has('vim-gitgutter') || dotplug#has('vim-signify')
    call extend(g:airline_extensions, ['hunks'])
  endif
  if dotplug#has('gitsigns.nvim')
    call extend(g:airline_extensions, ['dotfiles_gitsigns_nvim'])
  endif
  if dotplug#has('coc.nvim')
    call extend(g:airline_extensions, ['coc', 'dotfiles_coclist'])
  endif
  if dotplug#has('vim-obsession')
    call extend(g:airline_extensions, ['obsession'])
  endif
  if get(g:, 'dotfiles_use_nvimlsp', 0)
    call extend(g:airline_extensions, ['dotfiles_use_nvimlsp'])
  endif

  let g:airline_detect_iminsert = 1
  let g:airline#extensions#tabline#left_sep = ' '
  let g:airline#extensions#tabline#left_alt_sep = ''

" }}}


" FZF {{{
  let g:fzf_command_prefix = ''

  command! -bar -bang Manpages call dotfiles#fzf#manpage_search(<bang>0)
  command! -bar -bang CListFuzzy call dotfiles#fzf#qflist_fuzzy(0, <bang>0)
  command! -bar -bang LListFuzzy call dotfiles#fzf#qflist_fuzzy(1, <bang>0)

  nnoremap <silent> <F1>      :<C-u>Helptags<CR>
  nnoremap <silent> <leader>f :<C-u>Files<CR>
  nnoremap <silent> <leader>b :<C-u>Buffers<CR>
  nnoremap <silent> <leader>m :<C-u>Manpages<CR>

  " <https://github.com/junegunn/fzf/blob/764316a53d0eb60b315f0bbcd513de58ed57a876/src/tui/tui.go#L496-L515>
  let $FZF_DEFAULT_OPTS = '--color=16'
  let g:fzf_layout = { 'down': '~40%' }
  let g:fzf_preview_window = ['right:noborder', 'ctrl-/']

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


" quickfix/location list {{{
  nmap [q <Plug>(qf_qf_previous)
  nmap ]q <Plug>(qf_qf_next)
  nmap [l <Plug>(qf_loc_previous)
  nmap ]l <Plug>(qf_loc_next)
  nmap Q <Plug>(qf_qf_toggle)
  " Jump to the currently selected error in the qflist again
  nnoremap <leader>q :<C-u>cc<CR>zv
  let g:qf_mapping_ack_style = 1
  " Pick and jump using fzf
  nnoremap <leader>z :<C-u>CListFuzzy<CR>
  let g:qf_bufname_or_text = 2
" }}}


nnoremap <silent> <F9> :<C-u>make!<CR>

command! -bar -bang RunFile execute (b:runfileprg[0] ==# ':' ? b:runfileprg[1:] : '!' . b:runfileprg)
nnoremap <silent> <F5> :<C-u>RunFile<CR>


if exists('*api_info')
  command! -bar -bang NvimApiCheatSheet call dotfiles#nvim_api_cheat_sheet#print()
endif


" uptime {{{
  function! Uptime() abort
    let time = float2nr(localtime() - g:dotfiles_boot_localtime)
    let d = time / 60 / 60 / 24
    let h = time / 60 / 60 % 24
    let m = time / 60 % 60
    let s = time % 60
    return (d > 0 ? printf('%dd ', d) : '') . printf('%02d:%02d:%02d', h, m, s)
  endfunction
  command! -bar Uptime echo Uptime()
" }}}
