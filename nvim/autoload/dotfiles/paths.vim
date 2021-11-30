" See also:
" <https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html>
" <https://www.freedesktop.org/wiki/Software/xdg-user-dirs/>
" <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/os/stdpaths.c>
" <https://github.com/dirs-dev/dirs-sys-rs/blob/v0.3.4/src/lib.rs>
" <https://github.com/dirs-dev/dirs-rs/blob/d1c9b298df17b7d6ad4c5bc1f42b59888113d182/src/lin.rs>

let g:dotfiles#paths#sep = has('win32') ? '\' : '/'

function! s:get_xdg_base_dir(env_var_name, default_path) abort
  let env_path = getenv(a:env_var_name)
  if !empty(env_path) && env_path[0] ==# '/'
    return env_path
  endif
  if !empty(a:default_path)
    return expand('~') . '/' . a:default_path
  endif
  return v:null
endfunction

function! dotfiles#paths#xdg_data_home() abort
  return s:get_xdg_base_dir('XDG_DATA_HOME', '.local/share')
endfunction

function! dotfiles#paths#xdg_config_home() abort
  return s:get_xdg_base_dir('XDG_CONFIG_HOME', '.config')
endfunction

function! dotfiles#paths#xdg_state_home() abort
  return s:get_xdg_base_dir('XDG_STATE_HOME', '.local/state')
endfunction

function! dotfiles#paths#xdg_bin_home() abort
  return s:get_xdg_base_dir('XDG_BIN_HOME', '.local/bin')
endfunction

function! dotfiles#paths#xdg_cache_home() abort
  return s:get_xdg_base_dir('XDG_CACHE_HOME', '.cache')
endfunction

function! dotfiles#paths#xdg_runtime_dir() abort
  return s:get_xdg_base_dir('XDG_RUNTIME_DIR', v:null)
endfunction
