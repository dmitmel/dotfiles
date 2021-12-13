" Inspired by
" 1. <https://github.com/anihm136/Ubuntu-configs/blob/7a48a9b6243a6f743d43c8c6d86b24b835e4b687/tag-nvim/config/nvim/after/ftplugin/lua.vim>
" 2. <https://gist.github.com/iagoleal/92bd781dae1926525cd5e049eb32d64b>
" 3. <https://github.com/xolox/vim-lua-ftplugin/blob/bcbf914046684f19955f24664c1659b330fcb241/autoload/xolox/lua.vim#L11-L55>
" See also:
" 1. Lua's implementation of require():
" <https://github.com/lua/lua/blob/v5.1.1/loadlib.c>
" <https://github.com/LuaJIT/LuaJIT/blob/v2.0/src/lib_package.c>
" 2. NVim's package loader for resolving in runtimepath:
" <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/lua/vim.lua#L56-L85>
" 3. How Vim sets updates package.path to match runtimepath:
" <https://github.com/vim/vim/blob/v8.2.3425/src/if_lua.c#L2368-L2431>
function! dotfiles#ftplugin_helpers#lua#includeexpr(fname) abort
  if exists('*luaeval')
    " In NVim this will only take care of resolving system libraries, in Vim
    " this should be able to handle RTP scripts as well. This is because Nvim
    " implements require() from RTP with `package.loaders` and regular Vim
    " modifies the ordinary `package.path`.
    let fname = luaeval('package.searchpath(_A, package.path)', a:fname)
    if fname isnot# v:null
      return fname
    endif
    if exists('*nvim_get_runtime_file')
      let fname = tr(a:fname, '.', '/')
      for fname in ['lua/'.fname.'.lua', 'lua/'.fname.'/init.lua']
        let fname = get(nvim_get_runtime_file(fname, v:false), 0, v:null)
        if fname isnot# v:null
          return fname
        endif
      endfor
    endif
  endif
  return tr(a:fname, '.', '/')
endfunction

function! dotfiles#ftplugin_helpers#lua#to_module_name(path) abort
  let path = fnamemodify(a:path, ':p')
  if dotfiles#utils#ends_with(path, '.lua')
    let path = has('win32') ? tr(path, '\', '/') : path
    for dir in dotfiles#utils#list_runtime_paths()
      let dir = (has('win32') ? tr(dir, '\', '/') : dir) . '/lua/'
      if dotfiles#utils#starts_with(path, dir)
        let path = path[len(dir):-5]
        if dotfiles#utils#ends_with(path, '/init')
          let path = path[:-6]
        endif
        return tr(path, '/', '.')
      endif
    endfor
  endif
  return ''
endfunction
