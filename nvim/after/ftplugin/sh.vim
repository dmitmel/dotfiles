exe dotfiles#ft#setlocal('iskeyword+=-')

" Use the default global `keywordprg` value (`:Man`) instead of the one from Neovim's ftplugin:
" <https://github.com/neovim/neovim/blob/v0.11.5/runtime/ftplugin/sh.vim#L56-L61>
exe dotfiles#ft#setlocal('iskeyword<')

" <https://github.com/vim/vim/issues/16801>
" <https://github.com/chrisbra/matchit/issues/50>
" <https://github.com/neovim/neovim/pull/32812>
" <https://github.com/vim/vim/commit/d49ba7b92a14e6f3c1c413d396df72d36e934f78>
if exists('loaded_matchit') && !exists('b:match_skip')
\  || b:match_skip is# "synIDattr(synID(line('.'),col('.'),0),'name') =~ 'shSnglCase'"
  call dotfiles#ft#set('match_skip', 's:Comment\|String\|shHereDoc\|shSnglCase')
endif
