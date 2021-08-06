" order of EOL detection
set fileformats=unix,dos,mac

set wildignore+=.git,.svn,.hg,.DS_Store,*~

" arguably one of the most useful mappings
nnoremap <silent><expr> <CR> empty(&buftype) ? ":call \<SID>write_this_and_write_all()\<CR>" : "\<CR>"
function s:write_this_and_write_all() abort
  " The `abort` in this function is necessary because it will prevent a second
  " attempt of writing from :wall from occuring had the first :write failed.
  write | wall
endfunction

set undofile
set updatetime=500


" ripgrep (rg) {{{
  if executable('rg')
    let s:rg_cmd = 'rg --hidden --follow'
    let s:rg_ignore = split(&wildignore, ',') + [
    \ 'node_modules', 'target', 'build', 'dist', '.stack-work', '.ccls-cache'
    \ ]
    let s:rg_cmd .= " --glob '!{'" . shellescape(join(s:rg_ignore, ','), 1) . "'}'"

    let &grepprg = s:rg_cmd . ' --vimgrep'
    set grepformat^=%f:%l:%c:%m
    let $FZF_DEFAULT_COMMAND = s:rg_cmd . ' --files'
    command! -bang -nargs=* Rg call fzf#vim#grep(s:rg_cmd . ' --column --line-number --no-heading --fixed-strings --smart-case --color always ' . shellescape(<q-args>, 1), 1, <bang>0)
    command! -bang -nargs=* Find Rg<bang> <args>
  endif

  nnoremap <leader>/ :<C-u>grep<space>

  function! s:grep_mapping_star_normal() abort
    let word = expand('<cword>')
    if !empty(word)
      let cmd = 'grep ' . shellescape('\b' . word . '\b', 1)
      call histadd('cmd', cmd)
      call feedkeys(":\<C-u>" . cmd, 'n')
    endif
  endfunction
  function! s:grep_mapping_star_visual() abort
    let tmp = @"
    normal! y
    let cmd = 'grep ' . shellescape(@", 1)
    call histadd('cmd', cmd)
    call feedkeys(":\<C-u>" . cmd, 'n')
    let @" = tmp
  endfunction
  nnoremap <leader>* <Cmd>call <SID>grep_mapping_star_normal()<CR>
  xnoremap <leader>* <Cmd>call <SID>grep_mapping_star_visual()<CR>
" }}}


" Netrw {{{
  " disable most of the Netrw functionality (because I use Ranger) except its
  " helper functions (which I use in my dotfiles)
  let g:loaded_netrwPlugin = 1
  " re-add Netrw's gx mappings since we've disabled them
  nnoremap <silent> gx <Cmd>call netrw#BrowseX(expand('<cfile>'),netrw#CheckIfRemote())<CR>
  " This one can be rewritten in a way to not clobber the yank register...
  " Most notably, the built-in mapping, which uses netrw#BrowseXVis(), doesn't
  " work and breaks the editor, at least for me.
  xnoremap <silent> gx y:<C-u>call netrw#BrowseX(@",netrw#CheckIfRemote())<CR>
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
      vnew | read # | normal! ggdd
      diffthis
      setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile readonly nomodifiable
      let &filetype = filetype
    endfunction
    command DiffWithSaved call s:DiffWithSaved()
  " }}}

  " Reveal {{{
    " Reveal file in the system file explorer
    function! s:Reveal(path) abort
      if has('macunix')
        " only macOS has functionality to really 'reveal' a file, that is, to open
        " its parent directory in Finder and select this file
        call system('open -R ' . fnamemodify(a:path, ':S'))
      else
        " for other systems let's not reinvent the bicycle, instead we open file's
        " parent directory using netrw's builtin function (don't worry, netrw is
        " always bundled with Nvim)
        call s:Open(a:path)
      endif
    endfunction
    command Reveal call s:Reveal(expand('%'))
  " }}}

  " Open {{{
    " opens file or URL with a system program
    function! s:Open(path) abort
      " HACK: 2nd parameter of this function is called 'remote', it tells
      " whether to open a remote (1) or local (0) file. However, it doesn't work
      " as expected in this context, because it uses the 'gf' command if it's
      " opening a local file (because this function was designed to be called
      " from the 'gx' command). BUT, because this function only compares the
      " value of the 'remote' parameter to 1, I can pass any other value, which
      " will tell it to open a local file and ALSO this will ignore an
      " if-statement which contains the 'gf' command.
      call netrw#BrowseX(a:path, 2)
    endfunction
    command -nargs=* -complete=file Open call s:Open(empty(<q-args>) ? expand('%') : <q-args>)
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

  " DragOut {{{
    " Shows a window for draging (-and-dropping) the currently opened file out.
    function! s:DragOut(path) abort
      if empty(a:path) | return | endif
      if !executable('dragon-drag-and-drop')
        echoerr 'Please install <https://github.com/mwh/dragon> for the DragOut command to work.'
        return
      endif
      execute '!dragon-drag-and-drop' shellescape(a:path, 1)
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
      let file = expand('<afile>')
      " check if this is a regular file and its path is not a URL
      if empty(&buftype) && !s:IsUrl(file)
        let dir = fnamemodify(file, ':h')
        if !isdirectory(dir) | call mkdir(dir, 'p') | endif
      endif
    endfunction
  " }}}

  " fix whitespace {{{
    function! s:FixWhitespaceOnSave() abort
      let pos = getcurpos()
      " remove trailing whitespace
      keeppatterns %s/\s\+$//e
      " remove trailing newlines
      keeppatterns %s/\($\n\s*\)\+\%$//e
      call setpos('.', pos)
    endfunction
  " }}}

  " auto-format with Coc.nvim {{{
    let g:coc_format_on_save_ignore = []
    function! s:FormatOnSave() abort
      let file = expand('<afile>')
      if IsCocEnabled() && !s:IsUrl(file) && index(g:coc_format_on_save_ignore, &filetype) < 0
        silent CocFormat
      endif
    endfunction
  " }}}

  function! s:OnSave() abort
    call s:FixWhitespaceOnSave()
    call s:FormatOnSave()
    call s:CreateDirOnSave()
  endfunction
  augroup vimrc-on-save
    autocmd!
    autocmd BufWritePre * call s:OnSave()
  augroup END

" }}}
