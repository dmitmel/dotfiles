if get(g:, 'indexed_search_mappings')
  " Remove these from the select mode:
  " <https://github.com/henrik/vim-indexed-search/blob/5af020bba084b699d0453f242d7d76711d64b1e3/plugin/indexed-search.vim#L144-L151>.
  " sunmap gd
  " sunmap gD
  sunmap *
  sunmap #
  sunmap g*
  sunmap g#
  sunmap n
  sunmap N

  " Continuation of VisualStarSearch.
  xmap * <Plug>dotfiles_VisualStarSearch_*
  xmap # <Plug>dotfiles_VisualStarSearch_#
  xmap g* <Plug>dotfiles_VisualStarSearch_*
  xmap g# <Plug>dotfiles_VisualStarSearch_#
endif
