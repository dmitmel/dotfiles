set nocompatible
set cpoptions&vim
set encoding=utf-8

" Sensible defaults:
" <https://github.com/tpope/vim-sensible/blob/master/plugin/sensible.vim>
" <https://github.com/sheerun/vimrc/blob/master/plugin/vimrc.vim>
" <https://github.com/neovim/neovim/issues/2676>
" <https://github.com/neovim/neovim/issues/6289>
" <https://github.com/neovim/neovim/labels/defaults>

if !exists('g:dotfiles_boot_reltime')
  let g:dotfiles_boot_reltime = reltime()
  let g:dotfiles_boot_localtime = localtime()
endif

let g:nvim_dotfiles_dir = expand('<sfile>:p:h')
let g:dotfiles_dir = expand('<sfile>:p:h:h')

let g:vim_ide = get(g:, 'vim_ide', 0)
let g:dotfiles_build_coc_from_source = get(g:, 'dotfiles_build_coc_from_source', 0)
let g:dotfiles_sane_indentline_enable = get(g:, 'dotfiles_sane_indentline_enable', 1)

function! s:configure_runtimepath() abort
  execute 'set runtimepath-='.g:nvim_dotfiles_dir
  execute 'set runtimepath^='.g:nvim_dotfiles_dir
  execute 'set runtimepath-='.g:nvim_dotfiles_dir.'/after'
  execute 'set runtimepath+='.g:nvim_dotfiles_dir.'/after'
endfunction
call s:configure_runtimepath()

if empty($_COLORSCHEME_TERMINAL) && has('termguicolors')
  set termguicolors
endif

if has('nvim-0.2.1') || has('lua')
  lua _G.dotfiles = _G.dotfiles or {}
  if has('nvim')
    lua dotfiles.is_nvim = true
  else
    lua dotfiles.is_nvim = false
  endif
endif

" Make sure everybody knows that comma is the leader!
let g:mapleader = ','

" I want to load the colorscheme as early as possible, so that if any part of
" config crashes, we still get the correct highlighting and colors.
colorscheme dotfiles

if has('nvim-0.5.0')
  " Preload the Lua utilities.
  lua require('dotfiles.global_utils')
endif

" Disable the new Lua-based filetype detection system introduced in the newer
" Nvim versions.
let g:do_legacy_filetype = 1

call dotfiles#plugman#auto_install()
call dotfiles#plugman#begin()
runtime! dotfiles/plugins-list.vim
runtime! dotfiles/plugins-list.lua
call dotfiles#plugman#end()
" Automatically install/clean plugins (because I'm a programmer)
augroup dotfiles_init
  autocmd!
  autocmd VimEnter * call dotfiles#plugman#check_sync()
augroup END

if has('nvim-0.5.0')
  lua require('dotfiles.rplugin_bridge')
endif

" NOTE: What the following block does is effectively source the files
" `filetype.vim`, `ftplugin.vim`, `indent.vim`, `syntax/syntax.vim` from
" `$VIMRUNTIME` IN ADDITION TO sourcing the plugin scripts, `plugin/**/*.vim`.
" The last bit is very important because the rest of vimrc runs in a world when
" all plugins have been initialized, and so adjustments to e.g. autocommands
" are possible.
if has('autocmd') && !(exists('g:did_load_filetypes') && exists('g:did_load_ftplugin') && exists('g:did_indent_on'))
  filetype plugin indent on
endif
if has('syntax') && !exists('g:syntax_on')
  syntax enable
endif
