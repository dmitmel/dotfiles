" Guess what. The `syntax/jinja.vim` script for the jinja templating language,
" which is not included in neither Vim's runtime, nor Neovim's runtime, nor in
" vim-polyglot (so the only way to get it is to install the python package) is
" sourced in `syntax/nginx.vim` in vim-polyglot, which resets the `commentstring`
" set in `ftplugin/nginx.vim` and sets `comments` to some garbage. This script
" undoes that damage.
setlocal comments< commentstring=#%s

call dotfiles#utils#undo_ftplugin_hook('setlocal comments< commentstring<')
