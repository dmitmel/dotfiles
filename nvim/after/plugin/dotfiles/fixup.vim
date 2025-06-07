" For some reason, Lazy.nvim causes this script to be sourced the first time
" when `require('lazy').setup(...)` gets called, and then it is sourced the
" second time as part of the normal loading procedure. I guess this has
" something to do with its `performance.rtp.disabled_plugins` feature.
if !exists('g:dotfiles_fixup_plugins_ready')
  finish
endif

if exists('g:loaded_fzf_vim')
  " This command only works with Ultisnips, which I don't use, and gets in the
  " way when tab-completing nvim-snippy commands.
  delcommand Snippets
endif

" Disable netrw's autocommands. Note that I don't disable the entirety of netrw
" by setting `g:netrw_loadedPlugin` - that is because I use its `gx` mapping and
" its helper functions for opening URLs in the browser. And also, its
" functionality for downloading a file by editing a URL is super useful.
silent! autocmd! FileExplorer *
silent! augroup! FileExplorer

augroup dotfiles_session
  autocmd!
  let g:dotfiles_saved_shortmess = &shortmess
  autocmd SessionLoadPost * let &shortmess = g:dotfiles_saved_shortmess
augroup END

" Patch for the |eunuch-:Delete| command, to make it use my `:Bdelete` instead
" of |:bdelete|. The code in |eunuch-:Unlink| is close enough to parasitise on.
" <https://github.com/tpope/vim-eunuch/blob/e86bb794a1c10a2edac130feb0ea590a00d03f1e/plugin/eunuch.vim#L109-L119>
command! -bar -bang Delete try | Unlink<bang> | Bdelete<bang> | endtry
execute dotutils#cmd_alias('Del', 'Delete')

" This command must be added in `after/plugin/` because Vim 9+ and Nvim 0.11+
" define it by default without a bang, so I get startup errors otherwise.
" <https://github.com/vim/vim/commit/3d7e567ea7392e43a90a6ffb3cd49b71a7b59d1a>
" <https://github.com/neovim/neovim/commit/4913b7895cdd3fffdf1521ffb0c13cdeb7c1d27e>
" <https://github.com/neovim/neovim/commit/c1e020b7f3457d3a14e7dda72a4f6ebf06e8f91d>
command! -nargs=* -complete=file Open call dotutils#open_uri(empty(<q-args>) ? expand('%') : <q-args>)

command! -nargs=* -complete=file Reveal call dotutils#reveal_file(empty(<q-args>) ? expand('%') : <q-args>)

if exists(':Man') != 2
  " In regular Vim the :Man command is not defined by default, see `:h man.vim`
  runtime! ftplugin/man.vim
endif
