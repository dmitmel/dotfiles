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

if has('nvim')
  " Get rid of all default mappings defined here:
  " <https://github.com/neovim/neovim/blob/v0.11.0/runtime/lua/vim/_defaults.lua>
  mapclear
endif

let g:nvim_dotfiles_dir = expand('<sfile>:p:h')
let g:dotfiles_dir = expand('<sfile>:p:h:h')

let g:vim_ide = get(g:, 'vim_ide', 0)
let g:dotfiles_sane_indentline_enable = get(g:, 'dotfiles_sane_indentline_enable', 1)

" Make sure everybody knows that comma is the leader!
let g:mapleader = ','
" Use Nvim's new filetype detection system if it is available.
let g:do_filetype_lua = has('nvim')

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

function! s:start_self_debug_server(port) abort
  let osv_dir = g:dotplug#plugins_dir . '/one-small-step-for-vimkind'
  if !isdirectory(osv_dir)
    return
  endif
  let rtp = &runtimepath
  try
    lua <<EOF

    local osv_dir = vim.fn.eval('l:osv_dir')
    vim.opt.runtimepath:prepend(osv_dir)

    local osv = require('osv')

    -- The way OSV launches the headless Neovim by default is too brittle.
    -- See <https://github.com/jbyuki/one-small-step-for-vimkind/issues/62>.
    osv.on["start_server"] = function(_args, _env)
      local my_args = { vim.v.progpath, '-u', 'NONE', '-i', 'NONE', '-n', '--embed', '--headless' }
      local nvim = vim.fn.jobstart(my_args, { rpc = true })
      vim.fn.rpcrequest(nvim, 'nvim_exec_lua', 'vim.o.runtimepath = (...)', { osv_dir })
      return nvim
    end

    -- Fix for a typo here: <https://github.com/jbyuki/one-small-step-for-vimkind/blob/330049a237635b7cae8aef4972312e6da513cf91/src/launch.lua.t#L162-L163>
    osv.callback = osv.on

    osv.launch({ blocking = true, host = '127.0.0.1', port = vim.fn.eval('a:port') })

EOF
  catch
    call nvim_echo([ ['Error in ' . v:throwpoint . "\n" . v:exception, 'ErrorMsg'] ], v:true, {})
  finally
    let &runtimepath = rtp
  endtry
endfunction

call s:configure_runtimepath()

if has('nvim') && get(g:, 'dotfiles_debug_self_on_port', 0)
  call s:start_self_debug_server(g:dotfiles_debug_self_on_port)
endif

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

" I want to load the colorscheme as early as possible, so that if any part of
" config crashes, we still get the correct highlighting and colors.
colorscheme dotfiles

if has('nvim-0.5.0')
  " Preload the Lua utilities.
  lua require('dotfiles')
endif

call dotplug#auto_install()
call dotplug#begin()

runtime! dotfiles/plugins-list.vim
if has('nvim-0.5.0')
  runtime! dotfiles/plugins-list.lua
endif

call dotplug#end()
call s:configure_runtimepath()

augroup dotfiles_init
  autocmd!
  autocmd VimEnter * call dotplug#check_sync()
augroup END

if has('nvim-0.5.0')
  lua require('dotfiles.rplugin_bridge')
endif

filetype plugin indent on
syntax enable
