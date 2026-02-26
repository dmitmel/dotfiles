exe dotfiles#ft#setlocal('iskeyword+=-')

" Use the default `keywordprg` value (`:Man`) instead of the one from Neovim's ftplugin:
" <https://github.com/neovim/neovim/blob/v0.11.5/runtime/ftplugin/zsh.vim#L24-L29>
exe dotfiles#ft#setlocal('keywordprg<')
