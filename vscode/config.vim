""""""""""""""""""""""""""""""""" Text editing """""""""""""""""""""""""""""""""

" Use VSCoded's built-in undo handling.
nnoremap u undo
nnoremap U undo
nnoremap <C-r> redo

" shift + undo = redo
nnoremap U redo
" yank to the end
nnoremap Y y$
" disable search highlighting
nnoremap \ :nohlsearch<CR>
xnoremap \ :nohlsearch<CR>
" search within the Visual selection
xnoremap / <esc>/\%V
xnoremap ? <esc>/\%V
" repeatable indent/dedent
xnoremap > editor.action.indentLines
xnoremap < editor.action.outdentLines
" my most beloved mapping: save by pressing Enter
nnoremap <CR> :write<CR>
" a handier shortcut for clipboard copying
nnoremap <leader>c "+
xnoremap <leader>c "+
" for some reason gw does not exist, I emulate my two most common use-cases
nnoremap gww m'gqq`'
xnoremap gw <esc>m'gvgq`'
" jump forward in the jumplist
nnoremap <C-n> <C-i>
" jump back in the jumplist
nnoremap <C-p> <C-o>
" Poor-man's line textobject
xnoremap il ^vvg_
xnoremap al 0vv$
" Poor-man's indent motions
nnoremap ( viio<esc>^
nnoremap ) vii<esc>^
" :grep word under cursor
nmap <leader>* m'viw<leader>*<esc>`'
" :grep the selection
xnoremap <leader>* workbench.action.findInFiles
" duplicate current line and comment it out
nnoremap <silent> <leader>[ m'yygccP`'
nnoremap <silent> <leader>] m'yygccp`'j

" " Motions with support for word wrapping (Normal mode)
" nnoremap j gj
" nnoremap k gk
" nnoremap gj j
" nnoremap gk k
" " Motions with support for word wrapping (Visual mode)
" xnoremap j gj
" xnoremap k gk
" xnoremap gj j
" xnoremap gk k



"""""""""""""""""""""""""""""""" vim-unimpaired """"""""""""""""""""""""""""""""

" insert a blank line
nnoremap [<space> m'O<esc>`'
nnoremap ]<space> m'o<esc>`'
" exchange lines
nnoremap [e m':move-2<CR>`'k
nnoremap ]e m':move+1<CR>`'j
" duplicate a line
nnoremap [d m':<C-u>t-<CR>`'
nnoremap ]d m':<C-u>t.<CR>`'
" quickfix list navigation
nnoremap [q editor.action.marker.prevInFiles
nnoremap ]q editor.action.marker.nextInFiles



""""""""""""""""" Access to the VSCode interface and its menus """""""""""""""""

nnoremap <space> workbench.action.showCommands
xnoremap <space> workbench.action.showCommands
nnoremap <leader>/ actions.find
nnoremap <leader>f workbench.action.quickOpen
nnoremap <leader>b workbench.action.showAllEditorsByMostRecentlyUsed
nnoremap <leader>p workbench.action.problems.focus
nnoremap Q workbench.actions.view.problems
nnoremap <leader>o workbench.files.action.showActiveFileInExplorer
nnoremap <leader>O workbench.action.files.openFolder
" nnoremap <leader>O workbench.action.closeSidebar
nnoremap <leader>n notifications.clearAll
nnoremap <leader>s workbench.action.gotoSymbol
nnoremap <leader>w workbench.action.showAllSymbols

nnoremap <leader>k workbench.action.openGlobalKeybindings
nnoremap <leader>K workbench.action.openGlobalKeybindingsFile
nnoremap <leader>t workbench.action.openSettingsJson
nnoremap <leader>T workbench.action.openSettings
nnoremap <leader>V vim.editVimrc



""""""""""""""""""""""""""""" Buffers and Windows """"""""""""""""""""""""""""""

nnoremap   <Tab> workbench.action.nextEditorInGroup
nnoremap <S-Tab> workbench.action.previousEditorInGroup
nnoremap    <BS> workbench.action.closeActiveEditor
" Window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
" Split the window and return to the previous buffer
nnoremap <leader>v <C-w>v<C-w>h<C-o>
nnoremap <leader>h <C-w>s<C-w>k<C-o>



"""""""""""""""""""""""""""""""""""""" Git """""""""""""""""""""""""""""""""""""

nnoremap <leader>ga git.stage
nnoremap <leader>gd git.openChange
nnoremap <leader>gs workbench.scm.focus
nnoremap [c workbench.action.editor.previousChange
nnoremap ]c workbench.action.editor.nextChange



"""""""""""""""""""""""""""""""""""""" LSP """""""""""""""""""""""""""""""""""""

nnoremap [g editor.action.marker.prev
nnoremap ]g editor.action.marker.next
nnoremap gd editor.action.revealDefinition
nnoremap gD editor.action.goToDeclaration
nnoremap gr editor.action.goToReferences
nnoremap K editor.action.showHover

" Thankfully gl remains unused!
nnoremap gl :vscode latex-workshop.synctex<CR>
xnoremap gl :<C-u>vscode latex-workshop.synctex<CR>
