if !dotplug#has('vimspector') | finish | endif

" <https://github.com/puremourning/vimspector/blob/5e24df822e278ee79abfc8c7110089a5322d1a3c/README.md#changing-the-default-signs>
sign define vimspectorBP            text=●  texthl=vimspectorBP
sign define vimspectorBPCond        text=◆  texthl=vimspectorBPCond
sign define vimspectorBPLog         text=◆  texthl=vimspectorBPLog
sign define vimspectorBPDisabled    text=●  texthl=vimspectorBPDisabled
sign define vimspectorPC            text==> linehl=vimspectorPCLine texthl=vimspectorPC numhl=vimspectorPC
sign define vimspectorPCBP          text=●> linehl=vimspectorPCLine texthl=vimspectorPC numhl=vimspectorPC
sign define vimspectorNonActivePC           linehl=CursorLine
sign define vimspectorCurrentThread text=>  linehl=vimspectorPCLine texthl=vimspectorPC numhl=vimspectorPC
sign define vimspectorCurrentFrame  text=>  linehl=vimspectorPCLine texthl=vimspectorPC numhl=vimspectorPC

augroup dotfiles_vimspector
  autocmd!
  let g:dotfiles_vimspector_active = 0
  autocmd User VimspectorUICreated  let g:dotfiles_vimspector_active = 1
  autocmd User VimspectorDebugEnded let g:dotfiles_vimspector_active = 0
augroup END

exe dotplug#define_loader_keymap('<Plug>load_vimspector', 'vimspector')
autocmd FuncUndefined vimspector#* ++once call dotplug#load('vimspector')

" <https://github.com/puremourning/vimspector/#mappings>
" <https://developer.chrome.com/docs/devtools/shortcuts/#sources>
nmap <silent> <A-'>   <Plug>load_vimspector<Plug>VimspectorStepOver
nmap <silent> <A-;>   <Plug>load_vimspector<Plug>VimspectorStepInto
nmap <silent> <A-:>   <Plug>load_vimspector<Plug>VimspectorStepOut
nmap <silent> <A-S-;> <Plug>load_vimspector<Plug>VimspectorStepOut
nmap <silent> <A-.>   <Plug>load_vimspector<Plug>VimspectorDownFrame
nmap <silent> <A-,>   <Plug>load_vimspector<Plug>VimspectorUpFrame
nmap <silent> <A-b>   <Plug>load_vimspector<Plug>VimspectorToggleBreakpoint
nmap <silent> <A-p>   <Plug>load_vimspector<Plug>VimspectorPause
nmap <silent> <A-c>   <Plug>load_vimspector<Plug>VimspectorContinue
nmap <silent> <A-r>   <Plug>load_vimspector<Plug>VimspectorRunToCursor

command! -bar DbgStart    call vimspector#Launch()
command! -bar DbgClose    call vimspector#Reset({'interactive': v:true})
command! -bar DbgStop     call vimspector#Stop()
command! -bar DbgRestart  call vimspector#Restart()
command! -bar DbgBreak    call vimspector#SetLineBreakpoint(expand('%'), line('.'), {})
command! -bar DbgBreakDel call vimspector#ClearLineBreakpoint(expand('%'), line('.'))
command! -nargs=? DbgBreakFunc call vimspector#AddFunctionBreakpoint(!empty(<q-args>) ? <q-args> : expand('<cexpr>'))
command! -bar DbgBreakClearAll call vimspector#ClearBreakpoints()

command! -nargs=1 -complete=custom,vimspector#CompleteExpr DbgBreakIf   call vimspector#SetLineBreakpoint(expand('%'), line('.'), {'condition': <q-args>})
command! -nargs=1 -complete=custom,vimspector#CompleteExpr DbgBreakHit  call vimspector#SetLineBreakpoint(expand('%'), line('.'), {'hitCondition': <q-args>})
command! -nargs=1 -complete=custom,vimspector#CompleteExpr DbgBreakLog  call vimspector#SetLineBreakpoint(expand('%'), line('.'), {'logMessage': <q-args>})
command! -nargs=1 -complete=custom,vimspector#CompleteExpr DbgEval      call vimspector#Evaluate(<q-args>)
command! -nargs=1 -complete=custom,vimspector#CompleteExpr DbgWatch     call vimspector#AddWatch(<q-args>)

command! -bar DbgStartLua lua require('osv').launch({ host = '127.0.0.1', port = 1234, blocking = true })

let g:vimspector_configurations = {}
let g:vimspector_adapters = {}

let g:vimspector_adapters['multi-session'] = {
\ 'host': '${host:localhost}',
\ 'port': '${port:1234}',
\}

let g:vimspector_configurations['Remote Attach'] = {
\ 'autoselect': v:false,
\ 'adapter': 'multi-session',
\ 'configuration': {
\   'request': 'attach',
\ },
\}

runtime! dotfiles/vimspector/*.vim
