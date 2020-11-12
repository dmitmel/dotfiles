" order of EOL detection
set fileformats=unix,dos,mac

set wildignore+=.git,.svn,.hg,.DS_Store,*~

" arguably one of the most useful mappings
nnoremap <silent><expr> <CR> empty(&buftype) ? ":write<bar>wall\<CR>" : "\<CR>"


" ripgrep (rg) {{{
  if executable('rg')
    let s:rg_cmd = "rg --hidden --follow"
    let s:rg_ignore = split(&wildignore, ',') + [
    \ 'node_modules', 'target', 'build', 'dist', '.stack-work'
    \ ]
    let s:rg_cmd .= " --glob '!{'" . shellescape(join(s:rg_ignore, ',')) . "'}'"

    let &grepprg = s:rg_cmd . ' --vimgrep'
    let $FZF_DEFAULT_COMMAND = s:rg_cmd . ' --files'
    command! -bang -nargs=* Rg call fzf#vim#grep(s:rg_cmd . ' --column --line-number --no-heading --fixed-strings --smart-case --color always ' . shellescape(<q-args>), 1, <bang>0)
    command! -bang -nargs=* Find Rg<bang> <args>
  endif
" }}}


" Netrw {{{
  " disable most of the Netrw functionality (because I use Ranger) except its
  " helper functions (which I use in my dotfiles)
  let g:loaded_netrwPlugin = 1
  " re-add Netrw's gx mappings since we've disabled them
  nnoremap <silent> gx <Cmd>call netrw#BrowseX(expand('<cfile>'),netrw#CheckIfRemote())<CR>
  xnoremap <silent> gx :<C-u>call netrw#BrowseXVis()<CR>
" }}}


" Ranger {{{
  let g:ranger_replace_netrw = 1
  let g:ranger_map_keys = 0
  nnoremap <silent> <Leader>o <Cmd>Ranger<CR>
  " ranger.vim relies on the Bclose.vim plugin, but I use Bbye.vim, so this
  " command is here just for compatitabilty
  command! -bang -complete=buffer -nargs=? Bclose Bdelete<bang> <args>
" }}}


" Commands {{{

  " DiffWithSaved {{{
    " Compare current buffer with the actual (saved) file on disk
    function s:DiffWithSaved()
      let l:filetype = &filetype
      diffthis
      vnew | read # | normal! ggdd
      diffthis
      setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile readonly nomodifiable
      let &filetype = l:filetype
    endfunction
    command DiffWithSaved call s:DiffWithSaved()
  " }}}

  " Reveal {{{
    " Reveal file in the system file explorer
    function s:Reveal(path)
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
    function s:Open(path)
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
    function s:EditGlob(...)
      for l:glob in a:000
        for l:name in glob(l:glob, 0, 1)
          execute 'edit' fnameescape(l:name)
        endfor
      endfor
    endfunction
    command -nargs=* -complete=file -bar EditGlob call s:EditGlob(<f-args>)
  " }}}

  " DragOut {{{
    " Shows a window for draging (-and-dropping) the currently opened file out.
    function s:DragOut(path)
      if empty(a:path) | return | endif
      if !executable('dragon-drag-and-drop')
        echoerr "Please install <https://github.com/mwh/dragon> for the DragOut command to work."
        return
      endif
      execute '!dragon-drag-and-drop '.shellescape(a:path)
    endfunction
    command -nargs=* -complete=file DragOut call s:DragOut(empty(<q-args>) ? expand('%') : <q-args>)
  " }}}


" }}}


" on save (BufWritePre) {{{

  function s:IsUrl(str)
    return a:str =~# '\v^\w+://'
  endfunction

  " create directory {{{
    " Creates the parent directory of the file if it doesn't exist
    function s:CreateDirOnSave()
      let l:file = expand('<afile>')
      " check if this is a regular file and its path is not a URL
      if empty(&buftype) && !s:IsUrl(l:file)
        let l:dir = fnamemodify(l:file, ':h')
        if !isdirectory(l:dir) | call mkdir(l:dir, 'p') | endif
      endif
    endfunction
  " }}}

  " fix whitespace {{{
    function s:FixWhitespaceOnSave()
      let l:pos = getpos('.')
      " remove trailing whitespace
      %s/\s\+$//e
      " remove trailing newlines
      %s/\($\n\s*\)\+\%$//e
      call setpos('.', l:pos)
    endfunction
  " }}}

  " auto-format with Coc.nvim {{{
    let g:coc_format_on_save_ignore = []
    function s:FormatOnSave()
      let l:file = expand('<afile>')
      if IsCocEnabled() && !s:IsUrl(l:file) && index(g:coc_format_on_save_ignore, &filetype) < 0
        silent CocFormat
      endif
    endfunction
  " }}}

  function s:OnSave()
    call s:FixWhitespaceOnSave()
    call s:FormatOnSave()
    call s:CreateDirOnSave()
  endfunction
  augroup vimrc-on-save
    autocmd!
    autocmd BufWritePre * call s:OnSave()
  augroup END

" }}}


" CtrlSF {{{
  nmap <leader>/ <Plug>CtrlSFPrompt
  nmap <leader>* <Plug>CtrlSFCwordPath
  xmap <leader>* <Plug>CtrlSFVwordPath
" }}}
