let g:vimspector_adapters['delve'] = {
\ 'name': 'delve',
\ 'variables': {
\   'dlvFlags': [],
\ },
\ 'command': ['dlv', 'dap', '--listen=127.0.0.1:${unusedLocalPort}', '*${dlvFlags}'],
\ 'port': '${unusedLocalPort}',
\ 'tty': v:true,
\}
