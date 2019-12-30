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
      let l:cmd = a:cmd
      if &modified
        let l:answer = confirm("Save changes?", "&Yes\n&No\n&Cancel")
        if l:answer is# 1      " Yes
          write
        elseif l:answer is# 2  " No
          let l:cmd .= '!'
        else                   " Cancel/Other
          return
        endif
      endif
      execute l:cmd
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
    \ 'whitespace': "\u21e5 ",
    \ 'linenr': '',
    \ 'maxlinenr': ' ',
    \ 'branch': '',
    \ 'notexists': " [?]",
    \ }

  let g:airline#extensions#branch#enabled = 1
  let g:airline#extensions#tabline#enabled = 1
  let g:airline#extensions#coc#enabled = 1

  let g:airline#extensions#tabline#left_sep = ' '
  let g:airline#extensions#tabline#left_alt_sep = ''

  let g:coc_status_error_sign = 'E:'
  let g:coc_status_warning_sign = 'W:'
  call airline#parts#define_function('coc#status', 'coc#status')

  function StatusLine_filesize()
    let l:bytes = getfsize(expand('%'))
    if l:bytes < 0 | return '' | endif

    let l:factor = 1
    for l:unit in ['B', 'K', 'M', 'G']
      let l:next_factor = l:factor * 1024
      if l:bytes < l:next_factor
        let l:number_str = printf('%.2f', (l:bytes * 1.0) / l:factor)
        " remove trailing zeros
        let l:number_str = substitute(l:number_str, '\v\.?0+$', '', '')
        return l:number_str . l:unit
      endif
      let l:factor = l:next_factor
    endfor
  endfunction
  call airline#parts#define_function('filesize', 'StatusLine_filesize')

  function s:airline_section_prepend(section, items)
    let g:airline_section_{a:section} = airline#section#create_right(a:items + ['']) . g:airline_section_{a:section}
  endfunction
  function s:airline_section_append(section, items)
    let g:airline_section_{a:section} = g:airline_section_{a:section} . airline#section#create_left([''] + a:items)
  endfunction
  function s:tweak_airline()
    if exists('*coc#status')
      call s:airline_section_prepend('x', ['coc#status'])
    endif
    call s:airline_section_append('y', ['filesize'])
  endfunction
  augroup vimrc-interface-airline
    autocmd!
    autocmd user AirlineAfterInit call s:tweak_airline()
  augroup END

" }}}


" FZF {{{
  nnoremap <silent> <F1>      <Cmd>Helptags<CR>
  nnoremap <silent> <leader>f <Cmd>Files<CR>
  nnoremap <silent> <leader>b <Cmd>Buffers<CR>
" }}}


" quickfix/location list {{{
  nmap [q <Plug>(qf_qf_previous)
  nmap ]q <Plug>(qf_qf_next)
  nmap [l <Plug>(qf_loc_previous)
  nmap ]l <Plug>(qf_loc_next)
  let g:qf_mapping_ack_style = 1
" }}}


" Terminal {{{
  augroup vimrc-terminal
    autocmd!
    autocmd TermOpen * IndentLinesDisable
  augroup END
" }}}


nnoremap <silent> <F9> <Cmd>make<CR>