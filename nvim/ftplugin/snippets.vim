" <https://github.com/garbas/vim-snipmate/blob/ed3c5426a20bf1c06d7980946ada34fd9f93320e/ftplugin/snippets.vim>

" Vim filetype plugin for SnipMate snippets (.snippets and .snippet files)

if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

let b:undo_ftplugin = "setl et< sts< cms< fdm< fde<"

" Use hard tabs
setlocal noexpandtab softtabstop=0

setlocal foldmethod=expr foldexpr=getline(v:lnum)!~'^\\t\\\\|^$'?'>1':1

setlocal commentstring=#\ %s
setlocal nospell
