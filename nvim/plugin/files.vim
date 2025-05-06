" order of EOL detection
set fileformats=unix,dos,mac

set wildignore+=.git,.svn,.hg,.DS_Store,*~

" arguably one of the most useful mappings
nnoremap <silent><expr> <CR> empty(&buftype) ? ":call \<SID>write_this_and_write_all()\<CR>" : "\<CR>"
function s:write_this_and_write_all() abort
  " The `abort` in this function is necessary because it will prevent a second
  " attempt of writing from :wall from occuring had the first :write failed.
  try
    write
    wall
  catch /^Vim(\%(write\|wall\)):/
    echohl ErrorMsg
    echomsg v:exception
    echohl None
  endtry
endfunction

" Automatically read the file if it has been changed by another process and on
" :checktime
set autoread

" Persistent undo history
set undofile
augroup dotfiles_undo_persistance
  autocmd!
  autocmd BufWritePre * if &l:undofile !=# &g:undofile | setlocal undofile< | endif
  autocmd BufWritePre /tmp/*,/var/tmp/*,/private/tmp/* setlocal noundofile
augroup END

" Time to wait before CursorHold (and also before writing the swap file...)
set updatetime=500

" Don't save :set options in the files created with :mksession and :mkview
set sessionoptions-=options viewoptions-=options

" Save variables named in ALLCAPS (without underscores) to viminfo/shada. Not
" sure how this is useful with any plugins, but vim-sensible does it.
if !empty(&viminfo)
  set viminfo^=!
endif

" Some weird trickery with the tags discovery mechanism which finds tags in the
" directories above the current one and which I don't want to explain.
if has('path_extra')
  setglobal tags-=./tags tags-=./tags; tags^=./tags;
endif

" For CCDL contributions:
set nofixendofline


" grep {{{

  if executable('rg') " {{{
    let s:rg_cmd = 'rg --hidden --follow --smart-case'
    let s:rg_cmd .= ' --'.(&wildignorecase ? 'i' : '').'glob=' . shellescape('!{'.&wildignore.'}')
    let &grepprg = s:rg_cmd . ' --vimgrep'
    set grepformat^=%f:%l:%c:%m
    let $FZF_DEFAULT_COMMAND = s:rg_cmd . ' --files'
    command! -bang -nargs=* Rg call fzf#vim#grep(
    \ s:rg_cmd . ' --column --line-number --no-heading --color=always -- ' . shellescape(<q-args>),
    \ 1, fzf#vim#with_preview(), <bang>0)
    command! -bang -nargs=* Find Rg<bang> <args>
    " }}}
  elseif executable('ag') " {{{
    let s:ag_cmd = 'ag --hidden --follow --smart-case'
    let s:ag_cmd .= ' --ignore={' . join(map(split(&wildignore, ','), 'shellescape(v:val)'), ',') . '}'
    let &grepprg = s:ag_cmd . ' --vimgrep'
    set grepformat^=%f:%l:%c:%m
    let $FZF_DEFAULT_COMMAND = s:ag_cmd . " --search-binary --files-with-matches ''"
    command! -bang -nargs=* Ag call fzf#vim#grep(
    \ s:ag_cmd . ' --column --line-number --nogroup --color -- ' . shellescape(<q-args>),
    \ 1, fzf#vim#with_preview(), <bang>0)
    command! -bang -nargs=* Find Ag<bang> <args>
    " }}}
  else " plain ol' grep {{{
    " Short flags are used for compatibility with non-GNU grep implementations.
    " Note that -H is a GNU extension, yet is supported by the BSD and Busybox
    " grep. Long names of the flags:
    " -R = --dereference-recursive
    " -I = --binary-files=without-match
    " -n = --line-number
    " -H = --with-filename
    let &grepprg = 'grep -R -I -n -H'
  endif " }}}

  function! s:grep_word() abort
    let word = expand('<cword>')
    if !empty(word)
      let cmd = 'grep -- ' . shellescape('\b' . word . '\b', 1)
      " The `t` flag makes Vim treat the fed keys as if they were typed from
      " keyboard by the user. This is important for preserving the `:grep`
      " command in history.
      call feedkeys(":\<C-u>" . cmd, 'nt')
    endif
  endfunction
  nnoremap <silent> <leader>* :call <SID>grep_word()<CR>

  function! s:grep_visual() abort
    let tmp = @"
    try
      normal! gvy
      let text = @"
    finally
      let @" = tmp
    endtry
    let cmd = 'grep -F -- ' . shellescape(text, 1)
    call feedkeys(":\<C-u>" . cmd, 'nt')
  endfunction
  xnoremap <silent> <leader>* :<C-u>call <SID>grep_visual()<CR>

" }}}


" Ranger {{{
  let g:ranger_replace_netrw = 1
  let g:ranger_map_keys = 0
  " The default path (/tmp/chosenfile) is inaccessible at least on
  " Android/Termux, so the tempname() function was chosen because it respects
  " $TMPDIR.
  let g:ranger_choice_file = tempname()
  nnoremap <silent> <Leader>o :Ranger<CR>
  " ranger.vim relies on the Bclose.vim plugin, but I use Bbye.vim, so this
  " command is here just for compatitabilty
  command! -bang -complete=buffer -nargs=? Bclose Bdelete<bang> <args>
" }}}


" Commands {{{

  " DiffWithSaved {{{
    " Compare current buffer with the actual (saved) file on disk
    function! s:DiffWithSaved() abort
      let filetype = &filetype
      diffthis
      vnew
      setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nomodeline
      read #
      normal! ggdd
      setlocal readonly nomodifiable
      diffthis
      let &filetype = filetype
    endfunction
    command DiffWithSaved call s:DiffWithSaved()
  " }}}

  " EditGlob {{{
    " Yes, I know about the existence of :args, however it modifies the
    " argument list, so it doesn't play well with Obsession.vim because it
    " saves the argument list in the session file.
    function! s:EditGlob(...) abort
      for glob in a:000
        for name in glob(glob, 0, 1)
          execute 'edit' fnameescape(name)
        endfor
      endfor
    endfunction
    command -nargs=* -complete=file -bar EditGlob call s:EditGlob(<f-args>)
  " }}}

  " EditClist {{{
    function! s:EditList(...) abort
      let list = []
      for glob in a:000
        call extend(list, glob(glob, 0, 1))
      endfor
      call map(list, '{"filename": v:val, "lnum": 1}')
      call setqflist(list)
      copen
    endfunction
    command -nargs=* -complete=file -bar EditList call s:EditList(<f-args>)
  " }}}

  " DragOut {{{
    " Shows a window for draging (-and-dropping) the currently opened file out.
    function! s:DragOut(path) abort
      if empty(a:path) | return | endif
      for exe_name in ['dragon-drop', 'dragon-drag-and-drop']
        if executable(exe_name)
          execute '!'.exe_name shellescape(a:path, 1)
          return
        endif
      endfor
      echoerr 'Please install <https://github.com/mwh/dragon> for the DragOut command to work.'
    endfunction
    command -nargs=* -complete=file DragOut call s:DragOut(empty(<q-args>) ? expand('%') : <q-args>)
  " }}}

" }}}


" on save (BufWritePre) {{{

  let s:url_regex = '^\a\+://'

  " create parent directory of the file if it doesn't exist
  function! CreateParentDir() abort
    " check if this is a regular file and its path is not a URL
    if empty(&buftype) && expand('<afile>') !~# s:url_regex
      let dir = expand('<afile>:h')
      if !isdirectory(dir)  " <https://github.com/vim/vim/pull/2775>
        call mkdir(dir, 'p')
      endif
    endif
  endfunction

  function! FixWhitespace() abort
    let pos = getcurpos()
    " remove trailing whitespace
    keeppatterns %s/\s\+$//e
    " remove trailing newlines
    keeppatterns %s/\($\n\s*\)\+\%$//e
    call setpos('.', pos)
  endfunction

  let g:format_on_save_ignore = {}
  function! Format() abort
    let file = expand('<afile>')
    if get(g:format_on_save_ignore, &filetype, 0) || file =~# s:url_regex
      return
    endif
    if exists(':LspFormatSync')
      LspFormatSync
    elseif exists(':CocFormat')
      CocFormat
    endif
  endfunction

  command -bar Format        call Format()
  command -bar FormatIgnore  let g:format_on_save_ignore[&filetype] = 1

  augroup dotfiles_on_save
    autocmd!
    autocmd BufWritePre * call FixWhitespace()
    autocmd BufWritePre * call Format()
    autocmd BufWritePre * call CreateParentDir()
  augroup END

" }}}

augroup dotfiles_zip
  autocmd!
  " GeoGebra files
  autocmd BufReadCmd *.ggb    call zip#Browse(expand('<amatch>'))
  " Packed Crosscode mods
  autocmd BufReadCmd *.ccmod  call zip#Browse(expand('<amatch>'))
  " Firefox extensions
  autocmd BufReadCmd *.xpi    call zip#Browse(expand('<amatch>'))
  " Python wheels
  autocmd BufReadCmd *.whl    call zip#Browse(expand('<amatch>'))
augroup END


" Revert <https://github.com/tpope/vim-eunuch/commit/cceba47c032fee0f5fb467b7ada573c80ec15e57> {{{
function! s:SudoEditInit() abort
  if $SUDO_COMMAND =~# '^sudoedit '
    let files = split($SUDO_COMMAND, ' ')[1:-1]
    if len(files) ==# argc()
      for i in range(argc())
        execute 'autocmd BufEnter' fnameescape(argv(i))
        \ 'if empty(&filetype) || &filetype ==# "conf"'
        \ '|doautocmd filetypedetect BufReadPost' fnameescape(files[i])
        \ '|endif'
      endfor
    endif
  endif
endfunction
call s:SudoEditInit()
" }}}


nnoremap <leader>r :<C-u>Rename <C-r>=expand('%:t')<CR>


" Open the URL under cursor {{{

  " In nvim v0.11.0 `gx` was completely replaced with a Lua implementation:
  " <https://github.com/neovim/neovim/commit/4913b7895cdd3fffdf1521ffb0c13cdeb7c1d27e>
  " However, this a default mapping is set at editor startup, but also I
  " disable all default mappings from Neovim.
  " <https://github.com/vim/vim/commit/c729d6d154e097b439ff264b9736604824f4a5f4>

  function! s:gx_get_selection() abort
    let tmp = @"
    try
      normal! gvy
      return substitute(@", '[ \t\n\r]*', '', 'g')
    finally
      let @" = tmp
    endtry
  endfunction

  nnoremap <silent> gx      :call dotutils#open_uri(dotutils#url_under_cursor())<CR>
  xnoremap <silent> gx :<C-u>call dotutils#open_uri(<SID>gx_get_selection())<CR>

" }}}
