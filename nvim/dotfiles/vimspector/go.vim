" <https://github.com/puremourning/vimspector/blob/97984cafcf5e15befa05ec134d644e5e4f1c07f3/python3/vimspector/gadgets.py#L359-L375>
" <https://github.com/golang/vscode-go/blob/master/docs/debugging.md#launchjson-attributes>
let g:vimspector_adapters['delve'] = {
\ 'name': 'delve',
\ 'variables': {
\   'dlvFlags': [],
\ },
\ 'command': ['dlv', 'dap', '--listen=127.0.0.1:${unusedLocalPort}', '*${dlvFlags}'],
\ 'port': '${unusedLocalPort}',
\ 'tty': v:true,
\}
