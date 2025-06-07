if !dotplug#has('vimspector') | finish | endif

" <https://github.com/puremourning/vimspector/blob/ebeebc121423a5ab9a31c996f9881880b658c644/README.md#changing-the-default-signs>
let s:vimspector_signs = {
\ 'BP':            { 'prio': 30,  'text': '● ', 'numhl': 0 },
\ 'BPCond':        { 'prio': 30,  'text': '◆ ', 'numhl': 0 },
\ 'BPLog':         { 'prio': 30,  'text': '◆ ', 'numhl': 0 },
\ 'BPDisabled':    { 'prio': 30,  'text': '● ', 'numhl': 0 },
\ 'PC':            { 'prio': 200, 'text': ' ➤', 'numhl': 1 },
\ 'PCBP':          { 'prio': 200, 'text': '●➤', 'numhl': 1 },
\ 'CurrentThread': { 'prio': 200, 'text': '➤ ', 'numhl': 1 },
\ 'CurrentFrame':  { 'prio': 200, 'text': '➤ ', 'numhl': 1 },
\}

let g:vimspector_sign_priority = {}
for [s:sign_name, s:sign_conf] in items(s:vimspector_signs)
  let s:sign_name = 'vimspector'.s:sign_name
  let g:vimspector_sign_priority[s:sign_name] = s:sign_conf.prio
  call sign_define(s:sign_name, {
  \ 'text':   get(s:sign_conf, 'text', ''),
  \ 'texthl': get(s:sign_conf, 'texthl', 1) ? s:sign_name : '',
  \ 'numhl':  get(s:sign_conf, 'numhl',  0) ? s:sign_name : '',
  \})
endfor

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
