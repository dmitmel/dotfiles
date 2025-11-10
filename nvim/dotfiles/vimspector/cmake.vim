let g:vimspector_adapters['cmake'] = {
\ 'name': 'cmake',
\ 'command': ['socat', '-', 'UNIX-CONNECT:${workspaceRoot}/cmake-nvim-debug'],
\ 'configuration': {},
\}

let g:vimspector_configurations['cmake'] = {
\ 'autoselect': v:false,
\ 'adapter': 'cmake',
\ 'filetypes': ['cmake'],
\ 'configuration': {
\   'request': 'launch',
\ },
\}
