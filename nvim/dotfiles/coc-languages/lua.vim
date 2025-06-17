function! s:find_server() abort
  for s:server_dir in ['/usr/lib/lua-language-server', '/usr/local/opt/lua-language-server/libexec']
    if isdirectory(s:server_dir)
      return s:server_dir.'/bin/lua-language-server'
    endif
  endfor
  return 'lua-language-server'
endfunction

if has('nvim-0.2.1')
  let g:coc_user_config['Lua'] = luaeval('dotfiles.nvim_lua_dev.make_lua_ls_settings()')
endif

let s:data_path = dotutils#xdg_dir('cache') . '/lua-language-server'
let g:coc_user_config['languageserver.lua_ls'] = {
\ 'enable': v:true,
\ 'filetypes': ['lua'],
\ 'command': s:find_server(),
\ 'args': ['--logpath='.s:data_path.'/log', '--metapath='.s:data_path.'/meta'],
\ 'rootPatterns': ['.luarc.json', '.vim/', '.git/', '.hg/'],
\ 'settings': { 'Lua': get(g:coc_user_config, 'Lua', {}) },
\ }

let g:coc_user_config['languageserver.emmylua_ls'] = {
\ 'enable': v:false,
\ 'filetypes': ['lua'],
\ 'command': 'emmylua_ls',
\ 'args': ['--log-path='.s:data_path.'/log', '--resources-path='.s:data_path.'/meta'],
\ 'rootPatterns': ['.luarc.json', '.emmyrc.json', '.vim/', '.git/', '.hg/'],
\ 'settings': { 'Lua': get(g:coc_user_config, 'Lua', {}) },
\ 'disabledFeatures': ['formatting', 'documentFormatting', 'documentRangeFormatting', 'documentOnTypeFormatting'],
\ }

let g:coc_user_config['languageserver.efm'] = {
\ 'command': 'efm-langserver',
\ 'args': ['-c', expand('<sfile>:p:h:h:h').'/efm-langserver-config.json'],
\ 'filetypes': ['lua'],
\ }
