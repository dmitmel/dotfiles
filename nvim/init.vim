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

" `resolve()` is needed to support installation by symlinking this file directly
" into `~/.config/nvim/init.vim`.
let s:dotfiles_dir = resolve(expand('<sfile>:p:h'))

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
elseif !has('nvim') && !empty(globpath(&packpath, 'pack/*/opt/editorconfig'))
  packadd! editorconfig
endif

if has('nvim-0.11.3')
  " This fix must be present:
  " <https://github.com/neovim/neovim/commit/adf31505d862f740b49e22225f739f37093f9f03>
  autocmd! nvim.swapfile
endif

function! s:remove(list, element) abort
  let i = index(a:list, a:element)
  if i >= 0
    call remove(a:list, i)
  endif
endfunction

function! s:configure_runtimepath() abort
  let rtp = split(&runtimepath, ',')
  call s:remove(rtp, s:dotfiles_dir)
  call   insert(rtp, s:dotfiles_dir)
  call s:remove(rtp, s:dotfiles_dir . '/after')
  call      add(rtp, s:dotfiles_dir . '/after')
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

" Since v0.10.0, Neovim does automatic detection of 24-bit color support in the
" terminal by querying its capabilities. In other cases, such as in older
" versions of Nvim or in regular Vim, I only do a very rudimentary check as
" described here: <https://github.com/termstandard/colors#truecolor-detection>.
if has('termguicolors') && ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')
  set termguicolors
endif

" I want to load the colorscheme as early as possible, so that if any part of
" the config crashes, we still get the correct highlighting and colors.
colorscheme dotfiles

if has('nvim')
  " Expose the path to Neovim's binary to child processes, so that they can
  " unambiguously refer to it, even if it was run from a source build or an
  " AppImage, or is not even in the $PATH at all.
  let $NVIM_EXE = v:progpath
  " Also expose a shell command that the child processes can use to communicate
  " with the parent editor process.
  if has('nvim-0.7.0')
    " <https://gpanders.com/blog/whats-new-in-neovim-0-7/#client-server-communication>
    " <https://neovim.io/doc/user/remote.html>
    let s:remote_cmd = [v:progpath, '--server', v:servername, '--headless']
  else
    let s:nvr = exepath('nvr')
    let s:remote_cmd = !empty(s:nvr) ? [s:nvr, '--servername', v:servername] : []
  endif
  let $NVIM_REMOTE = join(map(s:remote_cmd, 'shellescape(v:val)'))
endif

if has('libcall') && has('unix') && !exists('$VIM_TTY')
  try
    " Provide the TTY that Vim is running in to `../scripts/icat`. This approach
    " is very hacky and non-portable, but I don't know of a cleaner way of doing
    " this. ttyname(3) returns path to the device of the terminal that is
    " connected to a given file descriptor. An empty string to |libcall()|
    " refers to libc, at least on GNU/Linux systems. Determining the file name
    " of libc portably on other systems is much harder:
    " <https://github.com/vim/vim/blob/110656ba607d22bbd6b1b25f0c05a1f7bad205c0/src/testdir/test_functions.vim#L2749-L2778>
    let $VIM_TTY = libcall(has('mac') ? 'libc.dylib' : '', 'ttyname', 1)
  catch /^Vim\%((\a\+)\)\=:\%(E364:\|dlerror = \)/
    " E364: Library call failed
  endtry
endif

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

let g:dotfiles_ready_to_fixup_plugins = 1  " see ./after/plugin/dotfiles/fixup.vim
