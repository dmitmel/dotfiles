if g:do_filetype_lua | finish | endif

" HACK: This is needed to reliably override ftdetection for `yarn.lock` files.
" In patch 9.1.0248 an autocommand has been added to the default `filetype.vim`
" to set the filetype of `yarn.lock` to `yaml` (which is incorrect); in order to
" override it, I need to declare an autocommand that fires earlier than the ones
" in Vim's default `filetype.vim` (the first filetype that gets set with `:setf`
" is the one that sticks). Scripts in the `ftdetect` folder are loaded too late,
" so the next best thing is to add a `filetype.vim` file that comes earlier in
" `&runtimepath` than `$VIMRUNTIME/filetype.vim` and put my autocommand there
" (all `filetype.vim` files from the RTP are loaded when the ftdetection system
" is initialized with `:filetype on`).
augroup filetypedetect
  autocmd BufNewFile,BufRead yarn.lock,.yarnrc setf conf
augroup END
