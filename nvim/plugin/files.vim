" Order of EOL detection.
set fileformats=unix,dos,mac

set wildignore+=.git,.svn,.hg,.DS_Store,*~

if !has('nvim')
  " Use global directories for storing undo/swap/backup files in plain ol' Vim.
  " Neovim does this out-of-the-box and that is so much nicer than cluttering
  " directories with random `*un~`, `.*.swp` and `*~` files! Apparently, on Arch
  " Linux they also configure Vim to do that by default:
  " <https://gitlab.archlinux.org/archlinux/packaging/packages/vim/-/blob/b9e5d92ac3e9cb865dc821ce9c18f6305108d02a/archlinux.vim#L22-40>
  function! s:set_dir_option(option_name, dir_name) abort
    " Only adjust those options which don't have the current directory as the first element.
    if split(eval('&'.a:option_name), ',')[0] !=# '.' | return | endif

    let dir = expand(has('win32') ? '$HOME/vimfiles' : '~/.vim') . '/' . a:dir_name
    if !isdirectory(dir)
      " These directories are created with restricted permissions as a mitigation for CVE-2017-1000382
      silent! call mkdir(dir, 'p', 0700)
    endif

    let dir .= '//'   " See |'directory'| for the meaning of the trailing double-backslash
    exe 'let &'.a:option_name.' = dir'
  endfunction

  call s:set_dir_option('directory', 'swap')
  call s:set_dir_option('undodir', 'undo')
  if has('patch-8.1.0251')  " <https://github.com/vim/vim/commit/b782ba475a3f8f2b0be99dda164ba4545347f60f>
    call s:set_dir_option('backupdir', 'backup')
  endif
endif

" Definitely one of my most useful mappings. Writes the current buffer and all
" other modified buffers to the disk. With regards to the implementation, I
" shold point out three major things:
"
" 1. In some buftypes <CR> has different Normal-mode behavior, for instance in
"    the quickfix list it opens the selected entry -- this is accounted for by
"    the <expr> condition. Note that this is not of concern if a plugin defines
"    a buffer-local mapping on <CR> because that will simply shadow and override
"    my global mapping, this matters only where the different behavior is a
"    implemented in Vim itself.
"
" 2. The useful payload after the buftype check is a bit convoluted, but that is
"    just a hack to ensure that |:wall| is not executed if |:write| fails or
"    gets cancelled (see |'confirm'|). This can't be done within a function or a
"    try-endtry block because then the stack trace is always displayed (I want a
"    one-line error message as if |:write| was typed in by hand).
"
" 3. The |:write| before |:wall| is executed so that the current buffer is
"    ALWAYS written, regardless of whether it was modified or not. This is
"    useful to kick off a build or to run on-save actions such as code
"    formatting.
"
nnoremap <silent><expr> <CR> (!empty(&buftype) && &buftype !=# 'acwrite') ? "\<CR>" :
\ ":\<C-u>let v:errmsg=''<bar>write<bar>if empty(v:errmsg) && !&modified<bar>wall<bar>endif\<CR>"

" Automatically reload the file if it was changed outside of Vim.
set autoread

" Persistent undo history
set undofile
augroup dotfiles_undo_persistance
  autocmd!
  autocmd BufWritePre * if &l:undofile != &g:undofile | setlocal undofile< | endif
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
  nnoremap <silent> <leader>* :<C-u>call <SID>grep_word()<CR>

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

  function! s:maybe_open_ranger(bufnr, path)
    if isdirectory(a:path)
      " I'm going to use :Bwipeout here precisely because it removes entries
      " related to the deleted buffer in the jumplist. When, let's say, a `gf`
      " command is ran over a directory name, then an entry will be added to
      " the jumplist corresponding to the directory. When the directory buffer
      " is wiped out, going backwards in the jumplist will instead take you to
      " the file from where `gf` was executed.
      execute 'Bwipeout' a:bufnr
      call dotfiles#ranger#run(['+edit', '--', a:path])
    endif
  endfunction

  augroup dotfiles_ranger
    autocmd!
    " The `nested` is a fix for <https://github.com/neovim/neovim/issues/34004>.
    " Also see <https://vi.stackexchange.com/questions/4521/when-exactly-does-afile-differ-from-amatch>.
    autocmd BufEnter * nested call s:maybe_open_ranger(expand('<abuf>'), expand('<amatch>'))
  augroup END

  " If a user command defined with `-complete=file` is invoked, Vim handles the
  " expansion of `%` for us, but doesn't process |backtick-expansion|s.
  command! -nargs=* -complete=file -bang Ranger call dotfiles#ranger#run(
  \ map(['+<mods> edit<bang>', <f-args>], "v:val =~# '^`.*`$' ? expand(v:val) : v:val"))

  " |`=| is so useful and I didn't know about it for years! It is essentially a
  " command substitution, similar to `$(...)` in the shell, it expands to the
  " result of the expression in the backticks. It works for all commands
  " expecting a |{file}|, such as |:edit|, and the returned string can contain
  " any |cmdline-special| characters without the need for escaping. Note that I
  " can't use just `--selectfile=%` here because that fails in buffers with an
  " empty name, whereas `expand('%')` returns an empty string just fine.

  " Open Ranger in the parent directory of the current buffer.
  nnoremap <silent> <Leader>o :<C-u>Ranger `='--selectfile='.expand('%')`<CR>
  " `cd` to the directory selected in Ranger.
  nnoremap <silent> <Leader>O :<C-u>Ranger `='--selectfile='.expand('%')` --choosedir +cd --cmd `='cd\ '.getcwd()`<CR>

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
    " Yes, I do know about the existence of :args, however, it modifies the
    " argument list, which for some reason is saved into the session file.
    function! s:EditGlob(...) abort
      for glob in a:000
        for name in expand(glob, 0, 1)
          edit `=name`
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

  let g:format_on_save = {}
  function! Format() abort
    if expand('<afile>') !~# s:url_regex && !&binary && &modifiable && &buftype !=# 'nofile' &&
    \  get(g:format_on_save, &filetype, 1) && get(b:, 'format_on_save', 1) &&
    \  !get(s:, 'noformat', 0)
      call FixWhitespace()
      if exists(':LspFixAll')
        " Automatic fixes must be applied BEFORE running the formatters!
        LspFixAll
      endif
      if exists(':LspFormat')
        LspFormat
      elseif exists(':CocFormat')
        CocFormat
      endif
    endif
  endfunction

  command -bar Format call Format()
  command -bar FormatIgnore let g:format_on_save[&filetype] = 0
  command -nargs=* -complete=command NoFormat let s:noformat = 1 | execute <q-args> | let s:noformat = 0
  execute dotutils#cmd_alias('nof', 'NoFormat')
  execute dotutils#cmd_alias('now', 'NoFormat write')

  augroup dotfiles_on_save
    autocmd!
    autocmd BufWritePre * call Format()
    autocmd BufWritePre * call CreateParentDir()
  augroup END

" }}}

augroup dotfiles_zip
  autocmd!
  " ggb - GeoGebra files
  " ccmod - packed Crosscode mods
  " xpi - Firefox extensions
  " whl - Python wheels
  autocmd BufReadCmd *.ggb,*.ccmod,*.xpi,*.whl call zip#Browse(expand('<amatch>'))
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

  nnoremap <silent> gx :<C-u>call dotutils#open_uri(dotutils#url_under_cursor())<CR>
  xnoremap <silent> gx :<C-u>call dotutils#open_uri(<SID>gx_get_selection())<CR>

" }}}
