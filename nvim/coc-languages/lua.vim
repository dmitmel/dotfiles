if !has('nvim-0.2.1') | finish | endif

let s:filetypes = {'lua': 1}
call extend(g:dotfiles_coc_filetypes, s:filetypes)

" The following is a port of `../dotfiles/lspconfigs/lua.lua`. See all of the
" interesting comments there.

function! s:get_server_settings() abort
  let cfg_package_path = []
  let cfg_libraries = {}

  let lua_package_config = split(luaeval('package.config'), '\n')
  let pc_dir_sep         = get(lua_package_config, 0, '/')
  let pc_path_list_sep   = get(lua_package_config, 1, ';')
  let pc_template_char   = get(lua_package_config, 2, '?')
  for rtp_dir in nvim_list_runtime_paths()
    let lua_dir = rtp_dir . pc_dir_sep . 'lua'
    if isdirectory(lua_dir)
      if !dotfiles#utils#starts_with(lua_dir, g:nvim_dotfiles_dir)
        let cfg_libraries[rtp_dir] = v:true
      endif
      " call add(cfg_package_path, lua_dir . pc_dir_sep . pc_template_char . '.lua')
      " call add(cfg_package_path, lua_dir . pc_dir_sep . pc_template_char . pc_dir_sep . 'init.lua')
    endif
  endfor
  call add(cfg_package_path, 'lua' . pc_dir_sep . pc_template_char . '.lua')
  call add(cfg_package_path, 'lua' . pc_dir_sep . pc_template_char . pc_dir_sep . 'init.lua')
  call extend(cfg_package_path, split(luaeval('package.path'), dotfiles#utils#literal_regex(pc_path_list_sep)))

  return {
  \ 'telemetry': { 'enable': v:false },
  \ 'runtime': { 'version': 'LuaJIT', 'path': cfg_package_path },
  \ 'workspace': { 'library': cfg_libraries },
  \ 'diagnostics': {
  \   'globals': ['vim'],
  \   'disable': ['empty-block'],
  \   'libraryFiles': 'Opened',
  \ },
  \ 'completion': {
  \   'workspaceWord': v:false,
  \   'showWord': 'Disable',
  \   'callSnippet': 'Replace',
  \ }
  \}
endfunction

let s:data_path = dotfiles#paths#xdg_cache_home() . '/lua-language-server'
let g:coc_user_config['languageserver.sumneko_lua'] = {
\ 'filetypes': keys(s:filetypes),
\ 'command': 'lua-language-server',
\ 'args': ['--logpath='.s:data_path.'/log', '--metapath='.s:data_path.'/meta'],
\ 'rootPatterns': ['.luarc.json', '.vim/', '.git/', '.hg/'],
\ 'settings': { 'Lua': s:get_server_settings() },
\ }
