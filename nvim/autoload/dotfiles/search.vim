" Loads all search results for the current buffer into a quickfix/location
" list. Based on <https://stackoverflow.com/a/1330556/12005228>, inspired by
" <https://gist.github.com/romainl/f7e2e506dc4d7827004e4994f1be2df6>, better
" than `vimgrep /pattern/ %`.
function! dotfiles#search#cmd_qf_search(is_loclist, pattern) abort
  let pattern = a:pattern
  if !empty(pattern)
    let @/ = pattern
    call histadd('search', pattern)
  else
    let pattern = @/
  endif

  let winnr = a:is_loclist ? winnr() : 0
  let bufnr = bufnr()
  let short_path = expand('%:.')
  let items = []
  let title = printf("Search /%s/ '%s'", escape(pattern, '/'), short_path)

  let saved_cursor_pos = getcurpos()

  call cursor(1, 1, 0)
  " c - "accept a match at the cursor position". The first match may be at the
  "    very start of the file, so we must check for it before advancing.
  " W - Disallow wrapscan, so that we don't get stuck in an infinite loop.
  let flags = 'cW'
  while search(pattern, flags) > 0
    call add(items, {
    \ 'bufnr': bufnr,
    \ 'lnum': line('.'),
    \ 'col': col('.'),
    \ 'vcol': virtcol('.'),
    \ 'text': getline('.'),
    \ })
    let flags = 'W'
  endwhile

  call setpos('.', saved_cursor_pos)

  call dotfiles#utils#push_qf_list({'title': title, 'items': items, 'dotfiles_loclist_window': winnr})
endfunction
