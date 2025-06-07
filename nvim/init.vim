set nocompatible
set cpoptions&vim
set encoding=utf-8

if exists('g:vscode')
  syntax off
  finish
endif

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

" 0 - no IDE features
" 1 - use coc.nvim as the IDE backend
" 2 - use the Neovim v0.5+ LSP client (needs at least Neovim v0.11 though)
let g:vim_ide = get(g:, 'vim_ide', 0)

" Make sure everybody knows that comma is the leader!
let g:mapleader = ','
" Use Nvim's new filetype detection system if it is available.
let g:do_filetype_lua = has('nvim-0.7.0')

" Modern versions of Vim and Neovim ship with built-in EditorConfig integration.
" <https://github.com/neovim/neovim/issues/3988>
" <https://github.com/vim/vim/issues/2286>
if has('nvim-0.9')
  let g:editorconfig = v:true
elseif !has('nvim')
  packadd editorconfig
endif

function! s:remove(list, element) abort
  let i = index(a:list, a:element)
  if i >= 0
    call remove(a:list, i)
  endif
endfunction

function! s:configure_runtimepath() abort
  let rtp = split(&runtimepath, ',')
  call s:remove(rtp, g:nvim_dotfiles_dir)
  call   insert(rtp, g:nvim_dotfiles_dir)
  call s:remove(rtp, g:nvim_dotfiles_dir . '/after')
  call      add(rtp, g:nvim_dotfiles_dir . '/after')
  let &runtimepath = join(rtp, ',')
endfunction

call s:configure_runtimepath()

let s:osv_port = str2nr($NVIM_DEBUG_LUA, 10)
let s:osv_dir = g:dotplug#plugins_dir . '/one-small-step-for-vimkind'
if s:osv_port != 0 && has('nvim') && isdirectory(s:osv_dir)
  call luaeval('vim.opt.runtimepath:prepend(_A)', s:osv_dir)
  lua require('osv').launch({ blocking = true, host = '127.0.0.1', port = vim.fn.eval('s:osv_port') })
  " This is Vimscript, so execution will continue even if there was an error
  " thrown on the previous line, so no try-finally block is necessary.
  call luaeval('vim.opt.runtimepath:remove(_A)', s:osv_dir)
endif

if has('termguicolors')
  set termguicolors
endif

" I want to load the colorscheme as early as possible, so that if any part of
" config crashes, we still get the correct highlighting and colors.
colorscheme dotfiles

if has('nvim-0.5.0')
  " Preload the Lua utilities.
  lua _G.dotfiles = require('dotfiles')
  lua _G.dotutils = require('dotfiles.utils')
endif

call dotplug#auto_install()
call dotplug#begin()
if has('nvim-0.5.0')
  lua _G.dotplug = require('dotplug')
endif

runtime! dotfiles/plugins-list.vim
if has('nvim-0.5.0')
  runtime! dotfiles/plugins-list.lua
endif

call dotplug#end()
call s:configure_runtimepath()  " Fixup the runtimepath after lazy.nvim.

augroup dotfiles_init
  autocmd!
  autocmd VimEnter * call dotplug#check_sync()
augroup END

filetype plugin indent on
syntax enable

let g:dotfiles_fixup_plugins_ready = 1  " see ./after/plugin/dotfiles/fixup.vim
