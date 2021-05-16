" always show the sign column
set signcolumn=yes

" enable bell everywhere
set belloff=

" title {{{
set title
let s:username = $USER
let s:hostname = substitute(hostname(), '\v^([^.]*).*$', '\1', '')  " get hostname up to the first '.'
let &titlestring = $USER . '@' . s:hostname . ': %F%{&modified ? g:airline_symbols.modified : ""} (nvim)'
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
    function s:CloseBuffer(cmd) abort
      let cmd = a:cmd
      if &modified
        let answer = confirm("Save changes?", "&Yes\n&No\n&Cancel")
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
    \ 'colnr': '',
    \ 'linenr': '',
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
    \ ]
  let g:airline_detect_iminsert = 1
  let g:airline#extensions#tabline#left_sep = ' '
  let g:airline#extensions#tabline#left_alt_sep = ''
  let g:airline#extensions#dotfiles_filesize#update_delay = 2
" }}}


" FZF {{{
  nnoremap <silent> <F1>      <Cmd>Helptags<CR>
  nnoremap <silent> <leader>f <Cmd>Files<CR>
  nnoremap <silent> <leader>b <Cmd>Buffers<CR>
  let g:fzf_layout = { 'down': '~40%' }
  let g:fzf_preview_window = ['right:noborder', 'ctrl-/']
" }}}


" quickfix/location list {{{
  nmap [q <Plug>(qf_qf_previous)
  nmap ]q <Plug>(qf_qf_next)
  nmap [l <Plug>(qf_loc_previous)
  nmap ]l <Plug>(qf_loc_next)
  let g:qf_mapping_ack_style = 1
" }}}


nnoremap <silent> <F9> <Cmd>make<CR>
