# partially based on https://github.com/chriskempson/base16-shell/blob/master/templates/default.mustache

source "${ZSH_DOTFILES:h}/colorschemes/out/zsh.zsh"

# When a terminal multiplexer is detected the control sequences for changing the
# colors need to be wrapped, so that they get passed through to the real terminal.
if [[ -n "$TMUX" ]]; then
  # The ESC characters in the wrapped OSC command must be escaped with another ESC.
  # https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it
  _colorscheme_send_ctrl_seq() { 1=${1//$'\e'/$'\e\e'}; printf '\ePtmux;\e%s\e\\' "$1"; }
elif [[ -n "$STY" ]]; then
  # <https://www.gnu.org/software/screen/manual/screen.html#Control-Sequences>
  # GNU screen uses the standard DCS (Device Control String) sequence, see
  # console_codes(4). It provides no means of escaping the ST sequence at the
  # end of an OSC though, but fortunately, xterm also recognizes OSC terminated
  # with the BEL character instead of ST. See also:
  # https://github.com/akinomyoga/ble.sh/blob/2f564e636f7b5dd99c4d9793277a93db29e81adf/src/util.sh#L7510-L7514
  _colorscheme_send_ctrl_seq() { 1=${1//$'\e\\'/$'\a'}; printf '\eP%s\e\\' "$1"; }
else
  _colorscheme_send_ctrl_seq() { printf '%s' "$1"; }
  # If a terminal multiplexer is now started in this terminal, the shell inside
  # will inherit this env variable, which tells it the real $TERM
  export DOTFILES_REAL_TERM="$TERM"
fi

_colorscheme_send_osc() {}
_colorscheme_set_attr() {}
_colorscheme_set_color() {}

case "${DOTFILES_REAL_TERM:-$TERM}" in
  (linux*)
    _colorscheme_set_color() {
      # Linux console supports setting only 16 ANSI colors and interestingly
      # enough uses only 8 of them
      if (( $1 >= 0 && $1 < 16 )); then
        _colorscheme_send_ctrl_seq $'\e]P'"$(([##16]$1))$2"
      fi
    }
    ;;
  (?*)
    _colorscheme_send_osc() { _colorscheme_send_ctrl_seq $'\e]'"$1"$'\e\\'; }
    _colorscheme_set_attr() { _colorscheme_send_osc "$1;rgb:${2[1,2]}/${2[3,4]}/${2[5,6]}"; }
    _colorscheme_set_color() { _colorscheme_set_attr "4;$1" "$2"; }
    ;;
esac

set-my-colorscheme() {
  local i; for (( i = 1; i <= ${#colorscheme_ansi_colors[@]}; i++ )); do
    _colorscheme_set_color "$((i-1))" "${colorscheme_ansi_colors[$i]}"
  done

  if [[ -n "$ITERM_SESSION_ID" ]]; then
    # iTerm2 proprietary escape codes
    # https://www.iterm2.com/documentation-escape-codes.html
    _colorscheme_send_osc Pg"$colorscheme_fg"
    _colorscheme_send_osc Ph"$colorscheme_bg"
    _colorscheme_send_osc Pi"$colorscheme_fg" # bold
    _colorscheme_send_osc Pj"$colorscheme_selection_bg"
    _colorscheme_send_osc Pk"$colorscheme_selection_fg"
    _colorscheme_send_osc Pl"$colorscheme_cursor_bg"
    _colorscheme_send_osc Pm"$colorscheme_cursor_fg"
  elif [[ -z "$VIM_TERMINAL" ]]; then
    _colorscheme_set_attr 10 "$colorscheme_fg"
    _colorscheme_set_attr 11 "$colorscheme_bg"
    # _colorscheme_set_attr 12 "$colorscheme_cursor_bg"
    # _colorscheme_set_attr 13 "$colorscheme_cursor_fg"
    # _colorscheme_set_attr 14 "$colorscheme_cursor_bg"
    _colorscheme_set_attr 17 "$colorscheme_selection_bg"
    _colorscheme_set_attr 19 "$colorscheme_selection_fg"
    if [[ "$DOTFILES_REAL_TERM" = rxvt* ]]; then
      # internal window border
      _colorscheme_set_attr 708 "$colorscheme_bg"
    fi
  fi
}

if [[ -z "$DOTFILES_DISABLE_MY_COLORSCHEME" ]]; then
  set-my-colorscheme
fi
