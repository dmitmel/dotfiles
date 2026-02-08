if !exists('current_compiler')
  compiler systemd-analyze
  call dotfiles#ft#undo('compiler make')
endif
