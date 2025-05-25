function! s:find_server() abort
  for s:server_dir in ['/usr/lib/lua-language-server', '/usr/local/opt/lua-language-server/libexec']
    if isdirectory(s:server_dir)
      return s:server_dir.'/bin/lua-language-server'
    endif
  endfor
  return 'lua-language-server'
endfunction

if has('nvim-0.2.1')
  let s:extra_settings = luaeval("require('dotfiles.lsp.nvim_lua_dev').lua_ls_settings_for_vim()")
endif

let g:coc_user_config['Lua'] = {
\ 'telemetry': { 'enable': v:false },
\ 'runtime': { 'path': s:extra_settings.package_path, 'version': 'LuaJIT' },
\ 'workspace': { 'library': s:extra_settings.libraries },
\ 'diagnostics': {
\   'globals': ['vim'],
\   'disable': ['empty-block'],
\   'libraryFiles': 'Opened',
\ },
\ 'completion': {
\   'workspaceWord': v:false,
\   'showWord': 'Disable',
\   'callSnippet': 'Replace',
\ },
\}

let s:data_path = dotutils#xdg_dir('cache') . '/lua-language-server'
let g:coc_user_config['languageserver.sumneko_lua'] = {
\ 'filetypes': ['lua'],
\ 'command': s:find_server(),
\ 'args': ['--logpath='.s:data_path.'/log', '--metapath='.s:data_path.'/meta'],
\ 'rootPatterns': ['.luarc.json', '.vim/', '.git/', '.hg/'],
\ 'settings': { 'Lua': g:coc_user_config['Lua'] },
\}
