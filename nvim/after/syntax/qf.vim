" Extension for <https://github.com/neovim/neovim/blob/v0.5.0/runtime/syntax/qf.vim>.

" Why aren't all of these highlighted by default?
" <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/quickfix.c#L3434-L3477>
syn clear qfError
syn match qfError   "error"   contained containedin=qfLineNr
syn match qfWarning "warning" contained containedin=qfLineNr
syn match qfInfo    "info"    contained containedin=qfLineNr
syn match qfNote    "note"    contained containedin=qfLineNr

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
