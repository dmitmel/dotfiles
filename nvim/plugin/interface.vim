" Replicate the behavior of Zsh's complist module under my configuration.
" 1st <Tab> - complete till the longest common prefix (longest).
" 2nd <Tab> - list the matches, but don't select or complete anything yet (list).
" 3rd <Tab> - start the selection menu (i.e. wildmenu), select and complete the first match (full).
set wildmenu wildmode=longest,list,full

" always show the sign column
set signcolumn=yes

" enable bell everywhere
set belloff=

" title {{{
set title
let s:username = $USER
let s:hostname = substitute(hostname(), '\v^([^.]*).*$', '\1', '')  " get hostname up to the first '.'
let &titlestring = $USER . '@' . s:hostname . ': %F%m (nvim)'
" }}}

" Yes, I occasionally use mouse. Sometimes it is handy for switching windows/buffers
set mouse=a
" <RightMouse> pops up a context menu
" <S-LeftMouse> extends a visual selection
set mousemodel=popup

" Maybe someday I'll use a Neovim GUI
if has('guifont')
  let &guifont = 'Ubuntu Mono derivative Powerline:h14'
endif


" Buffers {{{

  set hidden

  " open diffs in vertical splits by default
  set diffopt+=vertical

  " buffer navigation {{{
    noremap <silent> <Tab>   <Cmd>bnext<CR>
    noremap <silent> <S-Tab> <Cmd>bprev<CR>
    noremap <silent> gb      <Cmd>buffer#<CR>
  " }}}

  " ask for confirmation when closing unsaved buffers
  set confirm

  " Bbye with confirmation, or fancy buffer closer {{{
    function! s:CloseBuffer(cmd) abort
      let cmd = a:cmd
      if &modified
        " <https://github.com/neovim/neovim/blob/a282a177d3320db25fa8f854cbcdbe0bc6abde7f/src/nvim/ex_cmds2.c#L1400>
        let answer = confirm("Save changes to \"".expand('%')."\"?", "&Yes\n&No\n&Cancel")
        if answer ==# 1      " Yes
          write
        elseif answer ==# 2  " No
          let cmd .= '!'
        else                   " Cancel/Other
          return
        endif
      endif
      execute cmd
    endfunction
  " }}}

  " closing buffers {{{
    nnoremap <silent> <BS>  <Cmd>call <SID>CloseBuffer('Bdelete')<CR>
    nnoremap <silent> <Del> <Cmd>call <SID>CloseBuffer('Bdelete')<bar>quit<CR>
  " }}}

" }}}


" Windows {{{

  " window navigation {{{
    noremap <C-j> <C-w>j
    noremap <C-k> <C-w>k
    noremap <C-l> <C-w>l
    noremap <C-h> <C-w>h
  " }}}

  " switch to previous window
  noremap <C-\> <C-w>p

  " don't automatically make all windows the same size
  set noequalalways

  " closing windows {{{
    nnoremap <silent> <A-BS> <Cmd>quit<CR>
  " }}}

" }}}


" Airline (statusline) {{{

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
  let g:airline_extensions = [
    \ 'quickfix',
    \ 'fzf',
    \ 'term',
    \ 'hunks',
    \ 'branch',
    \ 'fugitiveline',
    \ 'coc',
    \ 'whitespace',
    \ 'wordcount',
    \ 'tabline',
    \ 'obsession',
    \ 'dotfiles_tweaks',
    \ 'dotfiles_filesize',
    \ 'dotfiles_coclist',
    \ ]
  let g:airline_detect_iminsert = 1
  let g:airline#extensions#tabline#left_sep = ' '
  let g:airline#extensions#tabline#left_alt_sep = ''
  let g:airline#extensions#dotfiles_filesize#update_delay = 2

  augroup vimrc-airline
    autocmd!
    autocmd User AirlineToggledOff set showmode
    autocmd User AirlineToggledOn set noshowmode
  augroup END

" }}}


" FZF {{{
  nnoremap <silent> <F1>      <Cmd>Helptags<CR>
  nnoremap <silent> <leader>f <Cmd>Files<CR>
  nnoremap <silent> <leader>b <Cmd>Buffers<CR>
  " <https://github.com/junegunn/fzf/blob/764316a53d0eb60b315f0bbcd513de58ed57a876/src/tui/tui.go#L496-L515>
  let $FZF_DEFAULT_OPTS = '--color=16'
  let g:fzf_layout = { 'down': '~40%' }
  let g:fzf_preview_window = ['right:noborder', 'ctrl-/']
" }}}


" quickfix/location list {{{
  nmap [q <Plug>(qf_qf_previous)
  nmap ]q <Plug>(qf_qf_next)
  nmap [l <Plug>(qf_loc_previous)
  nmap ]l <Plug>(qf_loc_next)
  let g:qf_mapping_ack_style = 1

  " Based on <https://stackoverflow.com/a/1330556/12005228>, inspired by
  " <https://gist.github.com/romainl/f7e2e506dc4d7827004e4994f1be2df6>.
  " But apparently `vimgrep /pattern/ %` can be used instead?
  function! s:CmdGlobal(pattern, bang) abort
    let pattern = substitute(a:pattern, "/.*$", "", "")
    let matches = []
    execute "g" . (a:bang ? "!" : "") . "/" . pattern . "/call add(matches, expand(\"%\").\":\".line(\".\").\":\".col(\".\").\":\".getline(\".\"))"
    cexpr matches
  endfunction
  command! -bang -nargs=1 Global call <SID>CmdGlobal(<q-args>, <bang>0)
" }}}


nnoremap <silent> <F9> <Cmd>make!<CR>
