if has('nvim-0.2.1')
  let g:coc_user_config['Lua'] = luaeval('dotfiles.nvim_lua_dev.make_lua_ls_settings()')
endif

augroup dotfiles_coc_lua
  autocmd!

  if v:false
    autocmd User CocNvimInit call coc#config('languageserver.emmylua_ls', #{
    \ filetypes: ['lua'],
    \ command: 'emmylua_ls',
    \ rootPatterns: ['.luarc.json', '.emmyrc.json'],
    \ settings: { 'Lua': coc#util#get_config('Lua') },
    \ })
  else
    autocmd User CocNvimInit call coc#config('languageserver.lua_ls', #{
    \ filetypes: ['lua'],
    \ command: 'lua-language-server',
    \ rootPatterns: ['.luarc.json', '.luarc.jsonc'],
    \ settings: { 'Lua': coc#util#get_config('Lua') },
    \ })
  endif
augroup END

let g:coc_user_config['languageserver.efm'] = #{
\ command: 'efm-langserver',
\ filetypes: ['lua'],
\ formatterPriority: 1,
\ initializationOptions: #{
\   documentFormatting: v:true,
\   documentRangeFormatting: v:true,
\ },
\}

let g:coc_user_config['languageserver.efm.settings.languages.lua'] = [#{
\ formatCommand: 'stylua --search-parent-directories --stdin-filepath=${INPUT} -',
\ formatStdin: v:true,
\}]
