" For some reason, Lazy.nvim causes this script to be sourced twice: the first
" time when `require('lazy').setup(...)` gets called, and the second time as
" part of the normal plugin loading procedure. I guess this has something to do
" with its `performance.rtp.disabled_plugins` feature. But anyway, the execution
" of this script is allowed only after lazy.nvim has been set up, at the very
" end of `../../../init.vim`.
if !exists('g:dotfiles_ready_to_fixup_plugins')
  finish
endif

if exists('g:loaded_fzf_vim') && exists(':Snippets') == 2 && !exists(':UltiSnipsEdit')
  " This command only works with Ultisnips, which I don't use.
  delcommand Snippets
endif

if exists('#dotfiles_ranger')
  " Disable netrw's autocommands. Note that I don't disable the entirety of
  " netrw by setting `g:netrw_loadedPlugin` - that is because I use its `gx`
  " mapping and its helper functions for opening URLs in the browser. And also,
  " its functionality for downloading a file by editing a URL is super useful.
  silent! autocmd! FileExplorer *
  silent! augroup! FileExplorer
endif

augroup dotfiles_session
  autocmd!

  autocmd SourcePre * let s:saved_shortmess = &shortmess
  if exists('##SourcePost')
    autocmd SourcePost * unlet! s:saved_shortmess
  endif

  autocmd SessionLoadPost *
  \ if exists('s:saved_shortmess')
  \|  let &shortmess = s:saved_shortmess
  \|  unlet s:saved_shortmess
  \|endif

  " Clear the argument list before saving the sessions and after loading them.
  " There is no option for this in |sessionoptions| and it is very annoying that
  " it is persisted in the session -- if some buffers were opened from the
  " command line and closed afterwards, they re-appear after reloading a saved
  " session.
  autocmd User ObsessionPre %argdel
  autocmd SessionLoadPost * %argdel
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

if has('nvim')
  command! -bar -bang -nargs=? -complete=command Sudo
    \ call dotfiles#nvim#sudo#enable('%') | <args>

  command! -bar -bang -nargs=? -complete=file SudoWrite
    \ call dotfiles#nvim#sudo#enable('%') |
    \ setlocal noreadonly |
    \ write<bang> <args>

  command! -bar -bang -nargs=? -complete=file SudoEdit
    \ call dotfiles#nvim#sudo#enable('%')
    \|setlocal noreadonly |
    \ let s:undoreload = &l:undoreload
    \|let &l:undoreload = 0
    \|try
    \|  exe 'edit<bang>' <q-args>
    \|finally
    \|  let &l:undoreload = s:undoreload
    \|  unlet s:undoreload
    \|endtry
endif

if exists(':Man') != 2
  " In regular Vim the :Man command is not defined by default, see `:h man.vim`
  runtime! ftplugin/man.vim
endif
