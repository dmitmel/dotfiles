" vint: -ProhibitAutocmdWithNoGroup

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

if get(g:, 'do_filetype_lua', 0) | finish | endif

autocmd BufNewFile,BufRead */etc/fonts/*.conf,*/fontconfig/*.conf setf xml
autocmd BufNewFile,BufRead */.clangd setf yaml
autocmd BufNewFile,BufRead */.latexmkrc setf perl
autocmd BufNewFile,BufRead */assets/*.json.patch setf json
autocmd BufNewFile,BufRead */.vimspector.json setf jsonc
autocmd BufNewFile,BufRead */snippets/*.json setf jsonc
