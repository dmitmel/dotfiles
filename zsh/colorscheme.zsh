#!/usr/bin/env bash
# partially based on https://github.com/chriskempson/base16-shell/blob/master/templates/default.mustache

source "$ZSH_DOTFILES/../colorschemes/out/shell.zsh"

if [[ -n "$TMUX" ]]; then
  # tmux
  terminal_wrapper=tmux
elif [[ -n "$STY" ]]; then
  # GNU Screen
  terminal_wrapper=screen
fi

if [[ -z "$terminal_wrapper" ]]; then
  case "$TERM" in
    linux*) terminal="linux" ;;
         *) terminal="xterm" ;;
  esac
  export _COLORSCHEME_TERMINAL="$terminal"
else
  terminal="${_COLORSCHEME_TERMINAL:-xterm}"
fi

# when a terminal wrapper is detected certain control sequences are used to
# send color change control sequences directly to the terminal
case "$terminal_wrapper" in
  tmux)
    # http://permalink.gmane.org/gmane.comp.terminal-emulators.tmux.user/1324
    _colorscheme_print_ctrl_seq() { print -n "\ePtmux;\e$1\e\\"; }
    ;;
  screen)
    # GNU screen uses the standard DCS (Device Control String) sequence (see
    # console_codes(4) manpage)
    _colorscheme_print_ctrl_seq() { print -n "\eP$1\e\\"; }
    ;;
  *)
    _colorscheme_print_ctrl_seq() { print -n "$1"; }
    ;;
esac; unset terminal_wrapper

case "$terminal" in
  linux)
    _colorscheme_print_osc_seq() {}
    _colorscheme_set_attr_to_color() {}
    _colorscheme_set_ansi_color() {
      # Linux console supports setting only 16 ANSI colors and interestingly
      # enough uses only 8 of them
      if (( $1 >= 0 && $1 < 16 )); then
        _colorscheme_print_ctrl_seq "$(printf "\e]P%X%s" "$1" "$2")"
      fi
    }
    ;;
  xterm)
    _colorscheme_print_osc_seq() {
      _colorscheme_print_ctrl_seq "\e]$1\a";
    }
    _colorscheme_set_attr_to_color() {
      _colorscheme_print_osc_seq "$1;rgb:${2[1,2]}/${2[3,4]}/${2[5,6]}";
    }
    _colorscheme_set_ansi_color() {
      _colorscheme_set_attr_to_color "4;$1" "$2";
    }
    ;;
esac; unset terminal

set-my-colorscheme() {
  local i; for (( i = 1; i <= ${#colorscheme_ansi_colors}; i++ )); do
    _colorscheme_set_ansi_color "$((i-1))" "${colorscheme_ansi_colors[$i]}"
  done

  if [[ -n "$ITERM_SESSION_ID" ]]; then
    # iTerm2 proprietary escape codes
    # https://www.iterm2.com/documentation-escape-codes.html
    _colorscheme_print_osc_seq Pg"$colorscheme_fg"
    _colorscheme_print_osc_seq Ph"$colorscheme_bg"
    _colorscheme_print_osc_seq Pi"$colorscheme_fg" # bold
    _colorscheme_print_osc_seq Pj"$colorscheme_selection_bg"
    _colorscheme_print_osc_seq Pk"$colorscheme_selection_fg"
    _colorscheme_print_osc_seq Pl"$colorscheme_cursor_bg"
    _colorscheme_print_osc_seq Pm"$colorscheme_cursor_fg"
  else
    _colorscheme_set_attr_to_color 10 "$colorscheme_fg"
    _colorscheme_set_attr_to_color 11 "$colorscheme_bg"
    if [[ "$TERM" = rxvt* ]]; then
      # internal window border
      _colorscheme_set_attr_to_color 708 "$colorscheme_bg"
    fi
  fi
}

set-my-colorscheme
