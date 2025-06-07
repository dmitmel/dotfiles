" See the complementary code in ../lua/dotplug.lua

let g:dotplug#implementation =
\ get(g:, 'dotplug#implementation', has('nvim-0.8.0') ? 'lazy.nvim' : 'vim-plug')

let g:dotplug#autoinstall = get(g:, 'dotplug#autoinstall', 1)
let g:dotplug#autoclean = get(g:, 'dotplug#autoclean', 1)

" vim-plug uses `https://git::@github.com/@s.git`, see
" <https://github.com/junegunn/vim-plug/issues/56#issuecomment-52072710>.
" However, authenication like that has been removed by GitHub:
" <https://docs.github.com/en/get-started/git-basics/about-remote-repositories#cloning-with-https-urls>.
let g:dotplug#url_format = 'https://github.com/%s.git'
" <https://github.com/folke/lazy.nvim/blob/6c3bda4aca61a13a9c63f1c1d1b16b9d3be90d7a/lua/lazy/core/loader.lua#L168-L172>
let g:dotplug#default_priority = 50

function! dotplug#(repo, ...) abort
  if a:0 > 1 | throw 'Invalid number of arguments for function (must be 1..2): ' . a:0 | endif
  let spec = get(a:000, 0, {})
  " Ensure consistency between vim-plug and lazy.nvim.
  " <https://github.com/junegunn/vim-plug/blob/fc2813ef4484c7a5c080021ceaa6d1f70390d920/plug.vim#L715>
  " <https://github.com/folke/lazy.nvim/blob/6c3bda4aca61a13a9c63f1c1d1b16b9d3be90d7a/lua/lazy/core/fragments.lua#L107-L121>
  let spec.as = get(spec, 'as', fnamemodify(a:repo, ':t:s?\.git$??'))
  let spec.priority = get(spec, 'priority', g:dotplug#default_priority)
  call s:dotplug_impl(a:repo, spec)
endfunction

function! dotplug#define_plug_here() abort
  return 'command! -nargs=+ Plug call dotplug#(<args>)'
endfunction

function! s:loader_mapping(lhs, plugin) abort
  call dotplug#load(a:plugin)
  execute 'map'  a:lhs '<nop>'
  execute 'map!' a:lhs '<nop>'
  return ''
endfunction

function! dotplug#define_loader_keymap(lhs, plugin) abort
  let cmds = []
  for map_cmd in ['noremap', 'noremap!']
    call add(cmds, printf('%s <silent><expr> %s %sloader_mapping(%s, %s)',
    \ map_cmd, a:lhs, expand('<SID>'), json_encode(a:lhs), json_encode(a:plugin)))
  endfor
  return join(cmds, "\n")
endfunction





if g:dotplug#implementation == 'lazy.nvim' && has('nvim-0.8.0') " {{{

let g:dotplug#repo = 'folke/lazy.nvim'
let g:dotplug#plugins_dir = get(g:, 'dotplug#plugins_dir', stdpath('data') . '/lazy')

function! dotplug#has(name) abort
  return v:lua.require'dotplug'.has(a:name)
endfunction

function! dotplug#plugin_dir(name) abort
  return v:lua.require'dotplug'.plugin_dir(a:name)
endfunction

function! dotplug#auto_install() abort
  let lazypath = g:dotplug#plugins_dir.'/lazy.nvim'
  if !isdirectory(lazypath)
    let lazyrepo = printf(g:dotplug#url_format, g:dotplug#repo)
    execute '!git clone --filter=blob:none --branch=stable -c advice.detachedHead=false --progress'
      \ shellescape(lazyrepo, 1) shellescape(lazypath, 1)
  endif
  call luaeval('vim.opt.runtimepath:prepend(_A)', lazypath)
endfunction

function! dotplug#begin() abort
  exe dotplug#define_plug_here()
endfunction

function! s:dotplug_impl(repo, spec) abort
  call v:lua.require'dotplug'.vimplug(a:repo, a:spec)
endfunction

function! dotplug#load(...) abort
  call v:lua.require'dotplug'.load(a:000)
endfunction

function! dotplug#end() abort
  call v:lua.require'dotplug'.end_setup()
endfunction

function! dotplug#check_sync() abort
endfunction

function! dotplug#complete_plugin_names(arg_lead, cmd_line, cursor_pos) abort
  return v:lua.require'dotplug'.plugin_names_completion()
endfunction





" }}}
elseif g:dotplug#implementation == 'vim-plug' " {{{

let g:dotplug#repo = 'junegunn/vim-plug'
let s:stdpath_config = exists('*stdpath') ? stdpath('config') : expand('~/.vim')
let g:dotplug#plugins_dir = get(g:, 'dotplug#plugins_dir', s:stdpath_config . '/plugged')

function! dotplug#has(name) abort
  return has_key(g:plugs, a:name) ? v:true : v:false
endfunction

function! dotplug#plugin_dir(name) abort
  return g:plugs[a:name].dir
endfunction

function! dotplug#auto_install() abort
  let s:install_path = 'autoload/plug.vim'
  if exists('*nvim_get_runtime_file') && !empty(nvim_get_runtime_file(s:install_path, 1))
    return
  elseif !empty(globpath(&runtimepath, s:install_path, 0, 1))
    return
  endif
  let s:install_path = s:stdpath_config . '/' . s:install_path
  execute '!curl -fL'
  \ shellescape('https://raw.githubusercontent.com/' . g:dotplug#repo . '/master/plug.vim', 1)
  \ '--create-dirs -o' shellescape(s:install_path, 1)
endfunction

function! dotplug#begin() abort
  let g:plug_url_format = g:dotplug#url_format
  call plug#begin(g:dotplug#plugins_dir)
  delcommand PlugUpgrade
  delcommand Plug
endfunction

function! s:dotplug_impl(repo, spec) abort
  if get(a:spec, 'lazy', 0)
    " If `{ 'on': [] }` is passed to vim-plug, then the plugin will be
    " installed, but won't get loaded until the first invocation of `plug#load`
    let a:spec.on = get(a:spec, 'on', [])
  endif
  if has_key(a:spec, 'version') && !has_key(a:spec, 'tag')
    let a:spec.tag = a:spec.version
  endif
  if get(a:spec, 'if', 1)
    call plug#(a:repo, a:spec)
  endif
endfunction

function! dotplug#load(...) abort
  call call('plug#load', a:000)
endfunction

function! dotplug#end() abort
  " The sort() function must be stable, meaning that we do not disrupt the order
  if v:version > 704 || (v:version == 704 && has("patch148"))
    " <https://github.com/folke/lazy.nvim/blob/6c3bda4aca61a13a9c63f1c1d1b16b9d3be90d7a/lua/lazy/core/loader.lua#L168-L172>
    let def_prio = g:dotplug#default_priority
    call sort(g:plugs_order, { name1, name2 -> get(g:plugs[name1], 'priority', def_prio) -
    \                                          get(g:plugs[name2], 'priority', def_prio) })
  endif
  call plug#end()
endfunction

function! dotplug#check_sync() abort
  let need_clean = {}
  " <https://stackoverflow.com/a/13908273/12005228>
  for subdir in glob(fnameescape(g:dotplug#plugins_dir) . '/{,.}*/', 1, 1)
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

  if !g:dotplug#autoinstall
    let need_install = {}
  endif
  if !g:dotplug#autoclean
    let need_clean = {}
  endif

  if !empty(need_install)
    PlugInstall --sync
  elseif !empty(need_clean)
    PlugClean
  endif
endfunction

function! dotplug#complete_plugin_names(arg_lead, cmd_line, cursor_pos) abort
  return join(keys(g:plugs), "\n")
endfunction





else
  echoerr "Invalid plugin manager choice:" string(dotplug#implementation)
endif   " }}}
