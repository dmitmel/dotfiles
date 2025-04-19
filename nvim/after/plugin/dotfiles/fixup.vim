if exists('g:loaded_fzf_vim')
  " This command only works with Ultisnips, which I don't use, and gets in the
  " way when tab-completing nvim-snippy commands.
  delcommand Snippets
endif

" Disable netrw's autocommands (kinda redundant since Ranger.vim does it
" already when `g:ranger_replace_netrw` is set). Note that I don't disable the
" entirety of netrw by setting `g:netrw_loadedPlugin` - that is because I use
" its `gx` mapping and its helper functions for opening URLs in the browser.
" And also, its functionality for downloading a file by editing a URL seems to
" be useful.
silent! autocmd! FileExplorer *
silent! augroup! FileExplorer

augroup dotfiles_session
  autocmd!
  let g:dotfiles_saved_shortmess = &shortmess
  autocmd SessionLoadPost * let &shortmess = g:dotfiles_saved_shortmess
augroup END


" Overrides <https://github.com/tpope/vim-eunuch/blob/7fb5aef524808d6ba67d6d986d15a2e291194edf/plugin/eunuch.vim#L74-L80>.
command! -bar -bang Delete
\ let s:l_file = expand('%:p')
\|execute 'ConfirmBdelete<bang>'
\|if !bufloaded(s:l_file) && dotutils#eunuch_fcall('delete', s:l_file)
\|  echoerr 'Failed to delete "'.s:l_file.'"'
\|endif |
\|unlet! s:l_file
command! -bar -bang Del Delete<bang>

" This command must be added in `after/plugin/` because Vim 9+ and Nvim 0.11+
" define it by default without a bang, so I get startup errors otherwise.
" <https://github.com/vim/vim/commit/3d7e567ea7392e43a90a6ffb3cd49b71a7b59d1a>
" <https://github.com/neovim/neovim/commit/4913b7895cdd3fffdf1521ffb0c13cdeb7c1d27e>
" <https://github.com/neovim/neovim/commit/c1e020b7f3457d3a14e7dda72a4f6ebf06e8f91d>
command! -nargs=* -complete=file Open call dotutils#open_uri(empty(<q-args>) ? expand('%') : <q-args>)

command! -nargs=* -complete=file Reveal call dotutils#reveal_file(empty(<q-args>) ? expand('%') : <q-args>)
