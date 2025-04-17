let s:filetypes = {'c': 1, 'cpp': 1, 'objc': 1, 'objcpp': 1}
call extend(g:dotfiles_coc_filetypes, s:filetypes)
call extend(g:dotfiles_coc_extensions, {'coc-clangd': 1})

let s:clangd_args = []
" Enables `.clangd` configuration files, see <https://clangd.llvm.org/config>.
call add(s:clangd_args, '--enable-config')
" Which binaries of compilers clangd is allowed to run to determine the system
" include paths and other such details about the compiler.
call add(s:clangd_args, '--query-driver='.expand('~').'/.platformio/packages/toolchain-*/bin/*')
call add(s:clangd_args, '--query-driver=/usr/bin/*')
call add(s:clangd_args, '--query-driver=/usr/local/bin/*')
call add(s:clangd_args, '--header-insertion=never')
let g:coc_user_config['clangd.arguments'] = s:clangd_args

" let s:cache_dir = dotfiles#paths#xdg_cache_home() . '/ccls'
" let g:coc_user_config['languageserver.ccls'] = {
" \ 'filetypes': keys(s:filetypes),
" \ 'command': 'ccls',
" \ 'rootPatterns': ['.ccls', 'compile_commands.json', '.vim/', '.git/', '.hg/'],
" \ 'initializationOptions': {
" \   'cache': { 'directory': s:cache_dir },
" \   'cacheDirectory': s:cache_dir,
" \   },
" \ }

" let g:coc_user_config['languageserver.clangd'] = {
" \ 'filetypes': keys(s:filetypes),
" \ 'command': 'clangd',
" \ 'args': s:clangd_args,
" \ 'rootPatterns': ['.clangd', 'compile_flags.txt', 'compile_commands.json', '.vim/', '.git/', '.hg/'],
" \ }

let g:coc_user_config['snippets.extends.cpp'] = ['c']
