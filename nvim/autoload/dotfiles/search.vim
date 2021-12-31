if exists('*searchcount')
  if has('timers')
    let s:show_count_timer = -1
    function! dotfiles#search#show_count(no_limits) abort
      call timer_stop(s:show_count_timer)
      let s:show_count_timer = timer_start(
      \ get(g:, 'indexed_search_debounce_time', 300),
      \ { timer -> timer == s:show_count_timer ? dotfiles#search#show_count_nowait(a:no_limits) : 0 })
    endfunction
  else
    function! dotfiles#search#show_count(no_limits) abort
      return dotfiles#search#show_count_nowait(a:no_limits)
    endfunction
  endif

  " Re-implementation of <https://github.com/henrik/vim-indexed-search/blob/763fdd0eb818ad441433aa04d00eabfda579476c/autoload/indexed_search.vim>
  " which uses the recently-added `searchcount()` function.
  " <https://github.com/neovim/neovim/commit/e498f265f46355ab782bfd87b6c85467da2845e3>
  " <https://github.com/vim/vim/commit/e8f5ec0d30b629d7166f0ad03434065d8bc822df>
  function! dotfiles#search#show_count_nowait(no_limits) abort
    let result = searchcount({
    \ 'recompute': 1,
    \ 'maxcount': a:no_limits ? 0 : get(g:, 'indexed_search_max_hits', 1000),
    \ 'timeout':  a:no_limits ? 0 : get(g:, 'indexed_search_timeout', 100),
    \ })

    " The following code is more-or-less a straight copy of
    " <https://github.com/henrik/vim-indexed-search/blob/763fdd0eb818ad441433aa04d00eabfda579476c/autoload/indexed_search.vim#L133-L182>.

    let matches = result.total
    if result.incomplete != 0 && result.total > result.maxcount
      let matches = '> '. result.total
    endif

    if result.total == 0
      let hl = 'Error'
      let msg = 'No matches'
    elseif result.incomplete != 0 && result.current > result.maxcount
      let hl = 'Directory'
      let msg = matches.' matches'
    elseif !result.exact_match && result.current == 0
      let hl = 'WarningMsg'
      let msg = 'Before '.(result.total == 1 ? 'single match' : 'last match of '. matches .' matches')
    elseif !result.exact_match && result.current == result.total
      let hl = 'WarningMsg'
      let msg = 'After '.(result.total == 1 ? 'single match' : 'last match of '. matches .' matches')
    elseif !result.exact_match
      let hl = 'Directory'
      let msg = 'Between matches '. result.current .'-'. (result.current+1) .' of '. matches
    elseif result.current == 1 && result.total == 1
      let hl = 'Search'
      let msg = 'Single match'
    elseif result.current == 1
      let hl = 'Search'
      let msg = 'First of '. matches .' matches'
    elseif result.current == result.total
      let hl = 'LineNr'
      let msg = 'Last of '. matches .' matches'
    else
      let hl = 'Directory'
      let msg = 'Match '. result.current .' of '. matches
    endif

    execute 'echohl' hl
    echo msg . '  /' . @/ . '/'
    echohl None
  endfunction
endif
