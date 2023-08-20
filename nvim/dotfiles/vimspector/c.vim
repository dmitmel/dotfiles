let s:filetypes = ['c', 'cpp', 'objc', 'objcpp', 'rust', 'swift']

" <https://github.com/microsoft/MIEngine> - the DAP server
" <https://github.com/Microsoft/vscode-cpptools> - the corresponding VSCode extension
" <https://code.visualstudio.com/docs/cpp/launch-json-reference> - options
" <https://github.com/microsoft/MIEngine/blob/v1.13.5/src/MIDebugPackage/OpenFolderSchema.json> - options
" <https://github.com/microsoft/vscode-cpptools/blob/v1.15.3/Extension/package.json#L3214-L4971> - options in VSCode
let g:vimspector_adapters['vscode-cpptools'] = {
\ 'name': 'cppdbg',
\ 'command': ['OpenDebugAD7'],
\ 'attach': { 'pidProperty': 'processId', 'pidSelect': 'ask' },
\ 'configuration': {
\   'type': 'cppdbg',
\   'args': [],
\   'cwd': '${workspaceRoot}',
\   'environment': [],
\   'stopAtEntry': v:false,
\   'externalConsole': v:false,
\ },
\}

let g:vimspector_configurations['cpptools: (gdb) Launch'] = {
\ 'autoselect': v:false,
\ 'adapter': 'vscode-cpptools',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'launch',
\   'program': '${program:${workspaceRoot\}/}',
\   'args': ['*${args}'],
\   'MIMode': 'gdb',
\   'MIDebuggerPath': exepath('gdb'),
\ },
\}

let g:vimspector_configurations['cpptools: (gdb) Attach'] = {
\ 'autoselect': v:false,
\ 'adapter': 'vscode-cpptools',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'attach',
\   'program': '${program:${workspaceRoot\}/}',
\   'MIMode': 'gdb',
\   'MIDebuggerPath': exepath('gdb'),
\ },
\}

let g:vimspector_configurations['cpptools: (gdb) Remote Attach'] = {
\ 'autoselect': v:false,
\ 'adapter': 'vscode-cpptools',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'attach',
\   'program': '${program:${workspaceRoot\}/}',
\   'MIMode': 'gdb',
\   'MIDebuggerServerAddress': '${address}',
\   'MIDebuggerPath': exepath('gdb'),
\ },
\}

" <https://github.com/vadimcn/codelldb> - the DAP server
" <https://github.com/vadimcn/codelldb/tree/master/extension> - the corresponding VSCode extension
" <https://github.com/vadimcn/codelldb/blob/master/MANUAL.md> - options
" <https://github.com/vadimcn/codelldb/blob/v1.9.1/package.json#L568-L1045> - options in VSCode
let g:vimspector_adapters['CodeLLDB'] = {
\ 'name': 'lldb',
\ 'command': ['codelldb', '--port', '${unusedLocalPort}'],
\ 'port': '${unusedLocalPort}',
\ 'attach': { 'pidProperty': 'pid', 'pidSelect': 'ask' },
\ 'configuration': {
\   'type': 'lldb',
\   'cargo': {},
\   'args': [],
\   'cwd': '${workspaceRoot}',
\   'env': {},
\   'stopOnEntry': v:false,
\   'terminal': 'integrated',
\   'relativePathBase': '${workspaceRoot}',
\ },
\}

let g:vimspector_configurations['CodeLLDB: Launch'] = {
\ 'autoselect': v:false,
\ 'adapter': 'CodeLLDB',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'launch',
\   'program': '${program}',
\   'args': ['*${args}'],
\ },
\}

let g:vimspector_configurations['CodeLLDB: Attach to PID'] = {
\ 'autoselect': v:false,
\ 'adapter': 'CodeLLDB',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'attach',
\ },
\}

let g:vimspector_configurations['CodeLLDB: Attach by Name'] = {
\ 'autoselect': v:false,
\ 'adapter': 'CodeLLDB',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'attach',
\   'pid': v:null,
\   'program': '${program}',
\ },
\}

" <https://github.com/llvm/llvm-project/tree/main/lldb/tools/lldb-vscode> - the DAP server
" <https://github.com/llvm/llvm-project/tree/main/lldb/tools/lldb-vscode#configurations> - options
" <https://github.com/llvm/llvm-project/blob/llvmorg-16.0.2/lldb/tools/lldb-vscode/package.json#L101-L348> - options in VSCode
let g:vimspector_adapters['lldb-vscode'] = {
\ 'name': 'lldb-vscode',
\ 'command': ['lldb-vscode'],
\ 'attach': { 'pidProperty': 'pid', 'pidSelect': 'ask' },
\ 'configuration': {
\   'type': 'lldb-vscode',
\   'args': [],
\   'cwd': '${workspaceRoot}',
\   'env': {},
\   'stopOnEntry': v:false,
\   'runInTerminal': v:true,
\ },
\}

let g:vimspector_configurations['lldb-vscode: Launch'] = {
\ 'autoselect': v:false,
\ 'adapter': 'lldb-vscode',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'launch',
\   'program': '${program}',
\   'args': ['*${args}'],
\ },
\}

let g:vimspector_configurations['lldb-vscode: Attach to PID'] = {
\ 'autoselect': v:false,
\ 'adapter': 'lldb-vscode',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'attach',
\ },
\}

let g:vimspector_configurations['lldb-vscode: Attach by Name'] = {
\ 'autoselect': v:false,
\ 'adapter': 'lldb-vscode',
\ 'filetypes': s:filetypes,
\ 'configuration': {
\   'request': 'attach',
\   'pid': v:null,
\   'program': '${program}',
\ },
\}
