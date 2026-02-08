setlocal iskeyword+=-
call dotfiles#ft#undo_set('&iskeyword')

" Use the default `keywordprg` value (`:Man`) instead of the one from Neovim's ftplugin:
" <https://github.com/neovim/neovim/blob/v0.11.5/runtime/ftplugin/sh.vim#L56-L61>
setlocal keywordprg<
call dotfiles#ft#undo_set('&keywordprg')
