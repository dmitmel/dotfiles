" I fixed this in <https://github.com/neovim/neovim/pull/34616>, this is just a backport.
if has('nvim-0.11.0') && !has('nvim-0.11.3')
  hi clear helpSectionDelim
  hi def healthSection gui=reverse cterm=reverse
  syn match healthSection /^======*\n.*$/hs=e contains=healthHeadingChar
endif
