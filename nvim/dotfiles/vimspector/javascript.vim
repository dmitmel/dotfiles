let s:filetypes = ['javascript', 'javascriptreact', 'typescript', 'typescriptreact']

" wget https://github.com/microsoft/vscode-js-debug/releases/download/v1.78.0/js-debug-dap-v1.78.0.tar.gz
" tar xavf js-debug-dap-v1.78.0.tar.gz
" echo "#\!/bin/sh\nexec node $PWD/js-debug/src/dapDebugServer.js \"\$@\"" > ~/.local/bin/vscode-js-debug
" chmod +x ~/.local/bin/vscode-js-debug

" <https://github.com/microsoft/vscode-js-debug> - the DAP server
" <https://github.com/microsoft/vscode-js-debug/blob/main/OPTIONS.md> - options
" <https://github.com/microsoft/vscode-js-debug/blob/main/src/build/generate-contributions.ts> - options in VSCode
let g:vimspector_adapters['js-debug'] = {
\ 'name': 'js-debug',
\ 'command': ['vscode-js-debug', '${unusedLocalPort}', '127.0.0.1'],
\ 'port': '${unusedLocalPort}',
\ 'attach': { 'pidProperty': 'processId', 'pidSelect': 'ask' },
\ 'configuration': {
\   'type': 'pwa-node',
\   'cwd': '${workspaceRoot}',
\   'localRoot': '${workspaceRoot}',
\   'console': 'integratedTerminal',
\   'skipFiles': ['<node_internals>/**'],
\ },
\}

let g:vimspector_configurations['Node.js: Current File'] = {
\ 'autoselect': v:false,
\ 'adapter': 'js-debug',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'launch',
\   'program': '${file}',
\   'args': ['*${args}'],
\ },
\}

let g:vimspector_configurations['Node.js: Attach'] = {
\ 'autoselect': v:false,
\ 'adapter': 'js-debug',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'attach',
\ },
\}

let g:vimspector_configurations['Node.js: Remote Attach'] = {
\ 'autoselect': v:false,
\ 'adapter': 'js-debug',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'attach',
\   'processId': v:null,
\   'address': '${host:localhost}',
\   'port': '${port:9229}',
\   'localRoot': '${workspaceRoot}',
\   'remoteRoot': '${remoteRoot:${workspaceRoot\}}',
\ },
\}

" <https://github.com/microsoft/vscode-node-debug2> - the DAP server
" <https://github.com/microsoft/vscode-node-debug2/blob/v1.43.0/src/nodeDebugInterfaces.d.ts> - options
" <https://github.com/microsoft/vscode-node-debug2/blob/v1.43.0/package.json#L189-L487> - options in VSCode
let g:vimspector_adapters['node-debug2'] = {
\ 'name': 'legacy-node2',
\ 'command': ['vscode-node-debug2'],
\ 'attach': { 'pidProperty': 'processId', 'pidSelect': 'ask' },
\ 'configuration': {
\   'type': 'legacy-node2',
\   'cwd': '${workspaceRoot}',
\   'console': 'integratedTerminal',
\   'skipFiles': ['<node_internals>/**'],
\ },
\}

let g:vimspector_configurations['Node.js (legacy): Current File'] = {
\ 'autoselect': v:false,
\ 'adapter': 'node-debug2',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'launch',
\   'program': '${file}',
\   'args': ['*${args}'],
\ },
\}

let g:vimspector_configurations['Node.js (legacy): Attach'] = {
\ 'autoselect': v:false,
\ 'adapter': 'node-debug2',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'attach',
\ },
\}

let g:vimspector_configurations['Node.js (legacy): Remote Attach'] = {
\ 'autoselect': v:false,
\ 'adapter': 'node-debug2',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'attach',
\   'processId': v:null,
\   'address': '${host:localhost}',
\   'port': '${port:9229}',
\   'localRoot': '${workspaceRoot}',
\   'remoteRoot': '${remoteRoot:${workspaceRoot\}}',
\ },
\}
