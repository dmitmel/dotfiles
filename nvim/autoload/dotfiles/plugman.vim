" The filename is totally not a reference to Arch'es package manager.

let g:dotfiles#plugman#implementation =
\ get(g:, 'dotfiles#plugman#implementation', has('nvim-0.8.0') ? 'lazy.nvim' : 'vim-plug')

let g:dotfiles#plugman#autoinstall = get(g:, 'dotfiles#plugman#autoinstall', 1)
let g:dotfiles#plugman#autoclean = get(g:, 'dotfiles#plugman#autoclean', 1)

" vim-plug uses `https://git::@github.com/@s.git`, see
" <https://github.com/junegunn/vim-plug/issues/56#issuecomment-52072710>.
" However, authenication like that has been removed by GitHub:
" <https://docs.github.com/en/get-started/git-basics/about-remote-repositories#cloning-with-https-urls>.
let g:dotfiles#plugman#url_format = 'https://github.com/%s.git'

function! dotfiles#plugman#register(repo, ...) abort
  if a:0 > 1 | throw 'Invalid number of arguments for function (must be 1..2): ' . a:0 | endif
  let spec = get(a:000, 0, {})
  if !has_key(spec, 'as')
    " Ensure consistency between vim-plug and lazy.nvim.
    " <https://github.com/junegunn/vim-plug/blob/fc2813ef4484c7a5c080021ceaa6d1f70390d920/plug.vim#L715>
    " <https://github.com/folke/lazy.nvim/blob/6c3bda4aca61a13a9c63f1c1d1b16b9d3be90d7a/lua/lazy/core/fragments.lua#L107-L121>
    let spec.as = fnamemodify(a:repo, ':t:s?\.git$??')
  endif
  call s:register_impl(a:repo, spec)
endfunction

function! dotfiles#plugman#define_commands() abort
  command! -nargs=+ -bar Plug call dotfiles#plugman#register(<args>)
endfunction




if g:dotfiles#plugman#implementation == 'lazy.nvim' && has('nvim-0.8.0') " {{{

let g:dotfiles#plugman#repo = 'folke/lazy.nvim'
let g:dotfiles#plugman#plugins_dir = get(g:, 'dotfiles#plugman#plugins_dir', stdpath('data') . '/lazy')

function! dotfiles#plugman#is_registered(name) abort
  return luaeval('dotfiles.plugman.find_plugin(_A) ~= nil', a:name)
endfunction

function! dotfiles#plugman#get_install_dir(name) abort
  return luaeval('dotfiles.plugman.find_plugin(_A).dir', a:name)
endfunction

function! dotfiles#plugman#auto_install() abort
  let lazypath = g:dotfiles#plugman#plugins_dir.'/lazy.nvim'
  if !isdirectory(lazypath)
    let lazyrepo = printf(g:dotfiles#plugman#url_format, g:dotfiles#plugman#repo)
    execute '!git clone --filter=blob:none --branch=stable -c advice.detachedHead=false --progress'
      \ shellescape(lazyrepo, 1) shellescape(lazypath, 1)
  endif
  execute 'set runtimepath^='.lazypath
endfunction

function! dotfiles#plugman#begin() abort
  lua require('lazy')
  lua require('dotfiles.plugman')
  call dotfiles#plugman#define_commands()
endfunction

function! s:register_impl(repo, spec) abort
  call v:lua.dotfiles.plugman.register_vimplug(a:repo, a:spec)
endfunction

function! dotfiles#plugman#end() abort
  call v:lua.dotfiles.plugman.end_setup()
endfunction

function! dotfiles#plugman#check_sync() abort
endfunction

function! dotfiles#plugman#command_completion(arg_lead, cmd_line, cursor_pos) abort
  return v:lua.dotfiles.plugman.plugin_names_completion()
endfunction



" }}}
elseif g:dotfiles#plugman#implementation == 'vim-plug' " {{{

let g:dotfiles#plugman#repo = 'junegunn/vim-plug'
let s:stdpath_config = exists('*stdpath') ? stdpath('config') : expand('~/.vim')
let g:dotfiles#plugman#plugins_dir = get(g:, 'dotfiles#plugman#plugins_dir', s:stdpath_config . '/plugged')


function! dotfiles#plugman#is_registered(name) abort
  return has_key(g:plugs, a:name) ? v:true : v:false
endfunction

function! dotfiles#plugman#get_install_dir(name) abort
  return g:plugs[a:name].dir
endfunction

function! dotfiles#plugman#auto_install() abort
  let s:install_path = 'autoload/plug.vim'
  if exists('*nvim_get_runtime_file') && !empty(nvim_get_runtime_file(s:install_path, 1))
    return
  elseif !empty(globpath(&runtimepath, s:install_path, 0, 1))
    return
  endif
  let s:install_path = s:stdpath_config . '/' . s:install_path
  execute '!curl -fL'
  \ shellescape('https://raw.githubusercontent.com/' . g:dotfiles#plugman#repo . '/master/plug.vim', 1)
  \ '--create-dirs -o' shellescape(s:install_path, 1)
endfunction

function! dotfiles#plugman#begin() abort
  let g:plug_url_format = g:dotfiles#plugman#url_format
  call plug#begin(g:dotfiles#plugman#plugins_dir)
  silent! delcommand PlugUpgrade
  call dotfiles#plugman#define_commands()
endfunction

function! s:register_impl(repo, spec) abort
  call plug#(a:repo, a:spec)
endfunction

function! dotfiles#plugman#end() abort
  call plug#end()
endfunction

function! dotfiles#plugman#check_sync() abort
  let need_clean = {}
  " <https://stackoverflow.com/a/13908273/12005228>
  for subdir in glob(fnameescape(g:dotfiles#plugman#plugins_dir) . '/{,.}*/', 1, 1)
    let subdir = fnamemodify(subdir, ":h:t")
    if subdir !=# "." && subdir !=# ".."
      let need_clean[subdir] = 1
    endif
  endfor

  let need_install = {}
  for name in keys(g:plugs)
    if !has_key(g:plugs[name], 'uri')
      continue
    endif
    if has_key(need_clean, name)
      unlet need_clean[name]
    else
      let need_install[name] = 1
    endif
  endfor

  if !g:dotfiles#plugman#autoinstall
    let need_install = {}
  endif
  if !g:dotfiles#plugman#autoclean
    let need_clean = {}
  endif

  if !empty(need_install) || !empty(need_clean)
    enew
    only
    call append(0, repeat(['PLEASE, RESTART THE EDITOR ONCE PLUGIN INSTALLATION FINISHES!!!'], 5))
    if !empty(need_install)
      PlugInstall --sync
    elseif !empty(need_clean)
      PlugClean
    endif
  endif
endfunction

function! dotfiles#plugman#command_completion(arg_lead, cmd_line, cursor_pos) abort
  return keys(g:plugs)
endfunction



else
  throw "Invalid plugin manager choice:" string(dotfiles#plugman#implementation)
end   " }}}
