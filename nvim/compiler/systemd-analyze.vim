" `:help write-compiler-plugin`
if exists('current_compiler')
  finish
endif
let current_compiler = 'systemd-analyze'

if exists(':CompilerSet') != 2
  command! -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=systemd-analyze\ verify\ %:S
CompilerSet errorformat=%f:%l:\ %m,%f:\ %m
