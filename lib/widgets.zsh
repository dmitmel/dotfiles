#!/usr/bin/env zsh

# define an associative array for widgets with their corresponding keybindings
typeset -A widgets_list
# get all widgets ('widgets' -> http://zsh.sourceforge.net/Doc/Release/Zsh-Modules.html#The-zsh_002fzleparameter-Module)
for widget_name widget_info in ${(kv)widgets}; do
  # ignore built-in widgets starting with a dot because ZSH defines them both
  # with and without the dot
  [[ "$widget_name" == .* ]] && continue
  # ignore completion widgets
  [[ "$widget_info" == completion:* ]] && continue
  # by default, widgets don't have keybindings
  widgets_list[$widget_name]="none"
done

# get keybindings for widgets (one widget can have multiple keybindings)

# iterate over existing keybindings (the 'f' flag splits output of the command
# by the '\n' char)
for line in "${(@f)$(bindkey)}"; do
  # parse line a string of command-line arguments (eval is required here!)
  eval "line_parts=($line)"
  # array indexes in ZSH start from 1 (o_O)
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

# convert list of widgets into a string
widgets_str=""
for widget_name widget_keys in ${(kv)widgets_list}; do
  widgets_str+="$widget_name"
  if [[ "$widget_keys" == keys:* ]]; then
    # remove the 'keys:' prefix
    widgets_str+=" ${widget_keys#keys:}"
  fi
  widgets_str+=$'\n'
done
# remove the trailing newline from the string
widgets_str="${widgets_str%$'\n'}"

unset widget_{name,info,key,keys}

# command palette allows you to search for widgets
_command-palette() {
  # widget is selected with 'peco', a 'Simplistic interactive filtering tool'
  local widget="$(echo "$widgets_str" | peco)"
  if [[ -n "$widget" ]]; then
    # parse widget name by cutting the selected string to the first space (which
    # may contain keybindings)
    widget="${widget%%$' '*}"
    # HACK: This small Python script is used to send simluated keystrokes to the
    #       currentl TTY. It first executes the 'execute-named-cmd' widget, then
    #       enters the widget name and finally types the 'Enter' key. (Python
    #       was chosen because it supports required functionallity out of the box).
    # NOTE! This script may not work on all platforms (especially, on Windows)!!!
    python -c "
import fcntl, termios
with open('$TTY') as tty:
  # ('\x1b' is the 'escape' char)
  for char in '\x1bx${widget}\n':
    # 'ioctl' is a syscall that can send special commands to file descriptors.
    # 'TIOCSTI' is one of these commands and can be used to simulate keypresses.
    fcntl.ioctl(tty, termios.TIOCSTI, char)
"
  fi
}
zle -N command-palette _command-palette
bindkey "^[P" command-palette            # Esc-Shift-P or Alt-Shift-P
