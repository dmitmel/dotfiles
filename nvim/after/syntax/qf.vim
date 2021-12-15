" Extension for <https://github.com/neovim/neovim/blob/v0.5.0/runtime/syntax/qf.vim>.

syn match qfLineNr "[^|]*" contained contains=qfError,qfWarning,qfInfo,qfNote

" Why aren't all of these highlighted by default?
" <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/quickfix.c#L3434-L3477>
syn match qfError   "error"   contained
syn match qfWarning "warning" contained
syn match qfInfo    "info"    contained
syn match qfNote    "note"    contained

if has('nvim-0.6.0')
  hi def link qfError   DiagnosticError
  hi def link qfWarning DiagnosticWarning
  hi def link qfInfo    DiagnosticInformation
  hi def link qfNote    DiagnosticHint
else
  hi def link qfError   LspDiagnosticsDefaultError
  hi def link qfWarning LspDiagnosticsDefaultWarning
  hi def link qfInfo    LspDiagnosticsDefaultInformation
  hi def link qfNote    LspDiagnosticsDefaultHint
endif
