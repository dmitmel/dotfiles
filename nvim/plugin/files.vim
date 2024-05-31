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

  nnoremap <leader>/ :<C-u>grep<space>

  function! s:grep_mapping_star_normal() abort
    let word = expand('<cword>')
    if !empty(word)
      let cmd = 'grep -- ' . shellescape('\b' . word . '\b', 1)
      call feedkeys(":\<C-u>" . cmd, 'nt')
    endif
  endfunction
  function! s:grep_mapping_star_visual() abort
    let tmp = @"
    normal! y
    let text = @"
    let @" = tmp
    let cmd = 'grep -- ' . shellescape(text, 1)
    call feedkeys(":\<C-u>" . cmd, 'nt')
  endfunction
  nnoremap <leader>* <Cmd>call <SID>grep_mapping_star_normal()<CR>
  xnoremap <leader>* <Cmd>call <SID>grep_mapping_star_visual()<CR>

" }}}


" Ranger {{{
  let g:ranger_replace_netrw = 1
  let g:ranger_map_keys = 0
  " The default path (/tmp/chosenfile) is inaccessible at least on
  " Android/Termux, so the tempname() function was chosen because it respects
  " $TMPDIR.
  let g:ranger_choice_file = tempname()
  nnoremap <silent> <Leader>o <Cmd>Ranger<CR>
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

  " Reveal {{{
    " Reveal file in the system file explorer
    function! s:Reveal(path) abort
      " TODO: Implement on Linux. See
      " <http://www.freedesktop.org/wiki/Specifications/file-manager-interface/>
      " <https://dbus.freedesktop.org/doc/dbus-python/tutorial.html>
      " <https://github.com/deluge-torrent/deluge/blob/deluge-2.0.5/deluge/common.py#L339-L377>
      " <https://github.com/GNOME/shotwell/blob/shotwell-0.31.3/src/util/system.vala#L24-L49>
      " <https://github.com/mixxxdj/mixxx/blob/2.3/src/util/desktophelper.cpp>
      " <https://github.com/mozilla/gecko-dev/blob/beb8961e1298f3a09f443ebd7374353d684923d2/xpcom/io/nsLocalFileUnix.cpp#L2083-L2108>
      " <https://github.com/mozilla/gecko-dev/blob/beb8961e1298f3a09f443ebd7374353d684923d2/toolkit/system/gnome/nsGIOService.cpp#L543-L632>
      " (NOTE: GPL code, must put into a separate binary to avoid licensing issues)
      if has('macunix')
        " only macOS has functionality to really 'reveal' a file, that is, to open
        " its parent directory in Finder and select this file
        call system('open -R ' . fnamemodify(a:path, ':S'))
      else
        " for other systems let's not reinvent the bicycle, instead we open file's
        " parent directory using netrw's builtin function (don't worry, netrw is
        " always bundled with Nvim)
        call dotfiles#utils#open_url(fnamemodify(a:path, ':h'))
      endif
    endfunction
    command Reveal call s:Reveal(expand('%'))
  " }}}

  " Open {{{
    command -nargs=* -complete=file Open call dotfiles#utils#open_url(empty(<q-args>) ? expand('%') : <q-args>)
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

  function! s:IsUrl(str) abort
    return a:str =~# '\v^\w+://'
  endfunction

  " create directory {{{
    " Creates the parent directory of the file if it doesn't exist
    function! s:CreateDirOnSave() abort
      " check if this is a regular file and its path is not a URL
      if empty(&buftype) && !s:IsUrl(expand('<afile>'))
        call mkdir(expand('<afile>:h'), 'p')
      endif
    endfunction
  " }}}

  " fix whitespace {{{
    " vint: -ProhibitCommandRelyOnUser -ProhibitCommandWithUnintendedSideEffect
    function! s:FixWhitespaceOnSave() abort
      let pos = getcurpos()
      " remove trailing whitespace
      keeppatterns %s/\s\+$//e
      " remove trailing newlines
      keeppatterns %s/\($\n\s*\)\+\%$//e
      call setpos('.', pos)
    endfunction
    " vint: +ProhibitCommandRelyOnUser +ProhibitCommandWithUnintendedSideEffect
    command! -bar FixWhitespace call s:FixWhitespaceOnSave()
  " }}}

  " auto-format with Coc.nvim {{{
    let g:coc_format_on_save_ignore = {}
    function! s:FormatOnSave() abort
      let file = expand('<afile>')
      if has_key(g:coc_format_on_save_ignore, &filetype) || s:IsUrl(file)
        return
      endif
      if exists(':LspFormatSync')
        LspFormatSync
      elseif exists(':CocFormat')
        CocFormat
      endif
    endfunction
  " }}}

  augroup dotfiles_on_save
    autocmd!
    autocmd BufWritePre * call s:FixWhitespaceOnSave()
    autocmd BufWritePre * call s:FormatOnSave()
    autocmd BufWritePre * call s:CreateDirOnSave()
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
