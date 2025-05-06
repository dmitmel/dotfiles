call dotutils#add_unique(g:coc_global_extensions, 'coc-clangd')

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

" let g:coc_user_config['languageserver.clangd'] = {
" \ 'filetypes': ['c', 'cpp', 'objc', 'objcpp'],
" \ 'command': 'clangd',
" \ 'args': s:clangd_args,
" \ 'rootPatterns': ['.clangd', 'compile_flags.txt', 'compile_commands.json', '.vim/', '.git/', '.hg/'],
" \}
