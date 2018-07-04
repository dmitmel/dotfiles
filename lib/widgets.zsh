#!/usr/bin/env zsh

_command_palette_widgets=()

for widget_name widget_info in ${(kv)widgets}; do
  [[ "$widget_name" == .* ]] && continue
  [[ "$widget_info" == completion:* ]] && continue
  _command_palette_widgets+=($widget_name)
done

_command-palette() {
  local widget_name="$(echo "${(@j:\n:)_command_palette_widgets}" | peco)"
  if [[ -n "$widget_name" ]]; then
    python -c "
import fcntl, termios
with open('$TTY') as tty:
  for char in '\x1bx$widget_name\n':
    fcntl.ioctl(tty, termios.TIOCSTI, char)
"
  fi
}
zle -N command-palette _command-palette
bindkey "^[P" command-palette
