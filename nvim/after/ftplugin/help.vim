if &buftype ==# 'help'
  setlocal signcolumn& colorcolumn=
endif

function! s:open_help_online()
  let tagstack = gettagstack()
  if tagstack.length < 1
    throw 'E73: tag stack empty'
  endif
  if tagstack.curidx == tagstack.length + 1
    let tag = tagstack.items[-1]
  else
    let tag = tagstack.items[tagstack.curidx - 1]
  endif
  let tagname = tag.tagname
  let file = bufname(tag.bufnr)

  let file = tr(file, '\', '/')
  let local_doc_prefix = resolve($VIMRUNTIME . '/doc/')
  if dotutils#starts_with(file, local_doc_prefix) && file =~? '\.txt$' && tagname =~# '@en$'
    let file = file[len(local_doc_prefix):-5]
    let tagname = tagname[:-4]

    let tagname = dotutils#url_encode(tagname, '')
    if has('nvim')
      let url = 'https://neovim.io/doc/user/' . file . '.html#' . tagname
    else
      let url = 'https://vimhelp.org/' . file . '.txt.html#' . tagname
    endif
    echomsg 'Opening ' . url
    call dotutils#open_uri(url)
  endif
endfunction

command! -bar -buffer OpenHelpOnline call s:open_help_online()
call dotfiles#ft#undo('silent! delcommand OpenHelpOnline')

nmap <buffer> gd <C-]>
nmap <buffer> gD <C-]>
nmap <buffer> gr :<C-u>helpgrep <C-r><C-w><CR>
call dotfiles#ft#undo_map('n', ['gd', 'gD', 'gr'])
