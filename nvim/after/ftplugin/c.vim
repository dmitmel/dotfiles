setlocal commentstring=//%s

" Let's just do a quick hack with regexes instead of figuring out the rules on
" which the `comments` list is split...
" <https://github.com/neovim/neovim/blob/523f03b506bf577811c0e136bc852cdb89f92c00/src/nvim/option.c#L2628-L2652>
let &l:comments = substitute(&l:comments, '\v%(^|,)\zs' . '://' . '\ze%(,|$)', ':///,://', '')

call dotfiles#utils#undo_ftplugin_hook('setlocal comments< commentstring<')
