" configure behaviour of wildmenu when I press <Tab> in the Vim command prompt
" 1. on the 1st <Tab>, complete the longest common prefix
" 2. on the 2nd <Tab>, list all available completions and open wildmenu
" this basically emulates Tab-completion behaviour in Zsh
set wildmode=list:longest,list:full

" always show the sign column
set signcolumn=yes

" enable bell everywhere
set belloff=

" title {{{
set title
let &titlestring = '%F%{&modified ? g:airline_symbols.modified : ""} (nvim)'
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
    noremap <silent> <Tab> :bnext<CR>
    noremap <silent> <S-Tab> :bprev<CR>
    noremap <silent> gb :buffer #<CR>
  " }}}

  " ask for confirmation when closing unsaved buffers
  set confirm

  " Bbye with confirmation, or fancy buffer closer {{{
    function s:CloseBuffer(cmd) abort
      let l:cmd = a:cmd
      if &modified
        let l:answer = confirm("Save changes?", "&Yes\n&No\n&Cancel")
        if l:answer is 1      " Yes
          write
        elseif l:answer is 2  " No
          let l:cmd .= '!'
        else                  " Cancel/Other
          return
        endif
      endif
      execute l:cmd
    endfunction
  " }}}

  " closing buffers {{{
    nnoremap <silent> <BS> :<C-u>call <SID>CloseBuffer('Bdelete')<CR>
    nnoremap <silent> <Del> :<C-u>quit <bar> call <SID>CloseBuffer('Bdelete')<CR>
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

  " splitting {{{
    noremap <silent> <leader>h :split<CR>
    noremap <silent> <leader>v :vsplit<CR>
  " }}}

  " closing windows {{{
    nnoremap <silent> <A-BS> :quit<CR>
  " }}}

" }}}


" Airline (statusline) {{{

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
  let g:airline#extensions#ale#enabled = 1

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
    call s:airline_section_prepend('x', ['coc#status'])
    call s:airline_section_append('y', ['filesize'])
    call s:airline_section_prepend('error', ['coc_error_count'])
    call s:airline_section_prepend('warning', ['coc_warning_count'])
  endfunction
  augroup vimrc-interface-airline
    autocmd!
    autocmd user AirlineAfterInit call s:tweak_airline()
  augroup END

" }}}


" FZF {{{
  nnoremap <silent> <F1> :Helptags<CR>
  nnoremap <silent> <leader>f :Files<CR>
  nnoremap <silent> <leader>b :Buffers<CR>
" }}}


" quickfix/location list {{{
  nmap [q <Plug>(qf_qf_previous)
  nmap ]q <Plug>(qf_qf_next)
  nmap [l <Plug>(qf_loc_previous)
  nmap ]l <Plug>(qf_loc_next)
  let g:qf_mapping_ack_style = 1
" }}}
