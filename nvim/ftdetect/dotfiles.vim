augroup dotfilesfiletypedetect

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

augroup END
