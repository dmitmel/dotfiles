if !has('nvim-0.2.1') | finish | endif

let s:filetypes = {'lua': 1}
call extend(g:dotfiles_coc_filetypes, s:filetypes)
call extend(g:dotfiles_coc_extensions, {'coc-sumneko-lua': 1, 'coc-stylua': 1})

let g:coc_user_config['stylua'] = {
\ 'styluaPath': exepath('stylua'),
\ 'checkUpdate': v:false,
\ 'configPath': g:nvim_dotfiles_dir . '/stylua.toml',
\}

for s:server_dir in ['/usr/lib/lua-language-server', '/usr/local/opt/lua-language-server/libexec']
  if isdirectory(s:server_dir)
    let g:coc_user_config['sumneko-lua.serverDir'] = s:server_dir
    break
  endif
endfor

let g:coc_user_config['sumneko-lua'] = {
\ 'prompt': v:false,
\ 'checkUpdate': v:false,
\}

let s:extra_settings = luaeval("require('dotfiles.lsp.nvim_lua_dev').lua_ls_settings_for_vim()")

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
\ 'format': { 'enable': !executable('stylua') },
\}

let s:data_path = dotfiles#paths#xdg_cache_home() . '/lua-language-server'
let g:coc_user_config['Lua.misc.parameters'] = ['--logpath='.s:data_path.'/log', '--metapath='.s:data_path.'/meta']
