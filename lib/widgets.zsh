#!/usr/bin/env zsh

typeset -A widgets_list
for widget_name widget_info in ${(kv)widgets}; do
  [[ "$widget_name" == .* ]] && continue
  [[ "$widget_info" == completion:* ]] && continue
  widgets_list[$widget_name]="none"
done

for line in "${(@f)$(bindkey)}"; do
  eval "line_parts=($line)"
  widget_key="$line_parts[1]"
  widget_name="$line_parts[2]"
  widget_keys="$widgets_list[$widget_name]"

  if [[ -z "$widget_keys" ]]; then
    continue
  else
    case "$widget_keys" in
      none) widget_keys="keys:" ;;
      keys:*) widget_keys+=" " ;;
    esac
    widgets_list[$widget_name]="$widget_keys{$widget_key}"
  fi
done

widgets_str=""
for widget_name widget_keys in ${(kv)widgets_list}; do
  widgets_str+="$widget_name"
  if [[ "$widget_keys" == keys:* ]]; then
    widgets_str+=" ${widget_keys#keys:}"
  fi
  widgets_str+=$'\n'
done
widgets_str="${widgets_str%$'\n'}"

unset widget_{name,info,key,keys}

_command-palette() {
  local widget="$(echo "$widgets_str" | peco)"
  if [[ -n "$widget" ]]; then
    widget="${widget%%$' '*}"
    python -c "
import fcntl, termios
with open('$TTY') as tty:
  for char in '\x1bx${widget}\n':
    fcntl.ioctl(tty, termios.TIOCSTI, char)
"
  fi
}
zle -N command-palette _command-palette
bindkey "^[P" command-palette
