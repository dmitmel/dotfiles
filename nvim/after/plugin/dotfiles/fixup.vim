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
\ let s:l_file = expand('%:p') |
\ execute 'ConfirmBdelete<bang>' |
\ if !bufloaded(s:l_file) && dotfiles#utils#eunuch_fcall('delete', s:l_file) |
\   echoerr 'Failed to delete "'.s:l_file.'"' |
\ endif |
\ unlet! s:l_file
command! -bar -bang Del Delete<bang>
