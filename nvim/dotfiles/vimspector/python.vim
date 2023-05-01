let s:filetypes = ['python']

" <https://github.com/microsoft/debugpy> - the DAP server
" <https://github.com/microsoft/vscode-python> - the corresponding VSCode extension
" <https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings> - options
" <https://code.visualstudio.com/docs/python/debugging> - options
" <https://github.com/microsoft/vscode-python/blob/2023.6.1/package.json#L1081-L1443> - options in VSCode
let g:vimspector_adapters['debugpy'] = {
\ 'name': 'debugpy',
\ 'command': ['python3', '-m', 'debugpy.adapter'],
\ 'attach': { 'pidProperty': 'processId', 'pidSelect': 'ask' },
\ 'configuration': {
\   'type': 'python',
\   'cwd': '${workspaceRoot}',
\   'justMyCode': v:false,
\   'console': 'integratedTerminal',
\   'stopOnEntry': v:false,
\ },
\}

let g:vimspector_configurations['Python: Current File'] = {
\ 'autoselect': v:false,
\ 'adapter': 'debugpy',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'launch',
\   'program': '${file}',
\   'args': ['*${args}'],
\ },
\}

let g:vimspector_configurations['Python: Attach'] = {
\ 'autoselect': v:false,
\ 'adapter': 'debugpy',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'attach',
\ },
\}

let g:vimspector_configurations['Python: Remote Attach'] = {
\ 'autoselect': v:false,
\ 'adapter': 'multi-session',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'attach',
\   'type': 'python',
\   'pathMappings': [ { 'localRoot': '${workspaceFolder}', 'remoteRoot': '.' } ],
\   'justMyCode': v:false,
\ },
\}
