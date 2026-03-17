if get(g:, 'do_filetype_lua', 0) | finish | endif
" vint: -ProhibitAutocmdWithNoGroup

autocmd BufNewFile,BufRead */etc/fonts/*.conf,*/fontconfig/*.conf setf xml
autocmd BufNewFile,BufRead */.clangd setf yaml
autocmd BufNewFile,BufRead */.latexmkrc setf perl
autocmd BufNewFile,BufRead */assets/*.json.patch setf json
autocmd BufNewFile,BufRead */.vimspector.json setf jsonc
autocmd BufNewFile,BufRead */pyrightconfig.json setf jsonc
autocmd BufNewFile,BufRead */snippets/*.json setf jsonc
