if exists('g:did_load_polyglot')
  " This will be remembered across reloads
  let s:has_polyglot = 1
endif
if exists('s:has_polyglot')
  " Makes polyglot not delete autocommands created in the ftdetect/*.vim files.
  " It will set this flags almost immediately after sourcing ftdetect files and
  " the stock filetype.vim has been inhibited already (see ../filetype.vim), so
  " this is fine.
  unlet! g:did_load_filetypes
endif

autocmd BufNewFile,BufRead */assets/*.json.patch setf json

autocmd BufNewFile,BufRead *.frag setf glsl

" Not sure if it fits here. Typescript's stock library declaration files (for
" the base language, ECMAScript editions, DOM etc) use mixed line endings for
" some unknown reason.
autocmd BufReadPost */node_modules/typescript/lib/lib.*.d.ts ++nested
\  if &l:fileformat !=# 'dos' && !exists('b:dotfiles_fileformat_checked')
\|   let b:dotfiles_fileformat_checked = 1
\|   execute 'edit ++ff=dos'
\| endif
" For re-opening the buffer (with manual `:e`, for example).
autocmd BufReadPre */node_modules/typescript/lib/lib.*.d.ts
\ unlet! b:dotfiles_fileformat_checked

autocmd BufNewFile,BufRead *.snippets setf snippets

autocmd BufNewFile,BufRead */etc/fonts/*.conf,*/fontconfig/*.conf setf xml

autocmd BufNewFile,BufRead */.clangd setf yaml

autocmd BufNewFile,BufRead */.vimspector.json setf jsonc
