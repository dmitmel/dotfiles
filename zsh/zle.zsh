# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Builtins
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Standard-Widgets

# FZF {{{
  # Based on <https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh>
  _fzf_history_widget() {
    local selected
    if selected=( $(fc -rl 1 | fzf --nth=2.. --scheme=history --query="$LBUFFER") ); then
      zle vi-fetch-history -n "${selected[1]}"
    fi
    # Can't use `zle redisplay` here, it may cause multiline prompts to move up
    # and "eat" the preceding text. More info here: <https://github.com/junegunn/fzf/pull/1397>.
    zle reset-prompt
  }

  # A brilliant HACK stolen from <https://github.com/junegunn/fzf/blob/4d563c6dfaf854260314cb5cdc9df577ec512805/shell/completion.zsh#L144-L150>.
  # This is a fake completion widget that does nothing but `eval` a string of
  # code passed to it. It has no effect on the state of the completion system,
  # besides letting us inspect its state from other functions, primarily to
  # access the completion-related variables described in zshcompwid(1).
  _fzf_eval_in_completion_widget() {
    eval "$@"
    compstate[insert]=""
    compstate[list]=""
  }
  zle -C _fzf_eval_in_completion_widget .complete-word _fzf_eval_in_completion_widget

  # Uses FZF to find a file and insert its path at the cursor position.
  # <https://github.com/lincheney/fzf-tab-completion/blob/master/zsh/fzf-zsh-completion.sh>
  _fzf_file_widget() {
    local word
    # Use the parser of the completion system to extract the word preceding the
    # cursor -- it handles all of the complexity of parsing partially typed in
    # code for us. This word will be used as a starting directory for FZF to
    # search files in, so that if you do e.g. `e /usr/bin/` and invoke this
    # widget, it will search for files in /usr/bin instead of the PWD.
    zle _fzf_eval_in_completion_widget -- 'word="$PREFIX"'

    local selected
    if selected="$(

      word="${word/#\~/$HOME}"  # expand a leading `~`
      if [[ -n "$word" ]]; then
        # don't invoke any chpwd handlers (-q) and ignore any errors from `cd`
        cd -q -- "$word" 2>/dev/null || true
      fi

      local prompt="%~"      # see EXPANSION OF PROMPT SEQUENCES in zshmisc(1)
      prompt="${(%)prompt}"  # perform prompt expansion
      prompt="${prompt%/}/"  # add a trailing slash if necessary

      # redirecting the /dev/tty to stdin is needed becaues of ZLE shenanigans
      # <https://unix.stackexchange.com/a/595386>
      fzf --prompt="$prompt" --scheme=path < /dev/tty

    )" && [[ -n "$selected" ]]; then
      # add syntactically-appropriate quoting for inserting ${selected}
      zle _fzf_eval_in_completion_widget -- 'compquote selected'
      LBUFFER+="${selected}"
    fi

    zle reset-prompt
  }

  zle -N _fzf_history_widget
  zle -N _fzf_file_widget
  bindkey '\er' _fzf_history_widget
  bindkey '\ef' _fzf_file_widget
# }}}

# palette {{{
  # This widget lets you select a command snippet and fill in its placeholders.
  # It uses "TLDR pages" as the snippet database, so the widget will download
  # them on the first invocation.  Or, you can also create a symlink to a local
  # cache of a "TLDR pages" client, e.g. for tealdeer (which is what I use):
  #
  #   ln -sv ~/.cache/tealdeer/tldr-master/pages $ZSH_CACHE_DIR/tldr-pages
  #
  # Usage:
  # 1. press Alt+Shift+P (or Esc+Shift+P)
  # 2. select snippet in the fuzzy finder (fzf)
  # 3. Press Alt+Shift+P again, this time it'll take you to the first placeholder
  # 4. Enter some text
  # 5. Repeat steps 3 and 4 until there're no placeholders left
  #
  # Requirements/Dependencies:
  # 1. AWK (any implementation will probably work) for parsing "TLDR pages"
  # 2. the FZF fuzzy finder
  # 3. Tar (any implementation will probably work) and Curl for downloading
  #    "TLDR pages"

  PALETTE_TLDR_PAGES_DIR="$ZSH_CACHE_DIR/tldr-pages"

  # strings which are used to mark placeholders (please don't modify)
  PALETTE_PLACEHOLDER_START="{{"
  PALETTE_PLACEHOLDER_END="}}"

  # a string which is used to separate snippet from its description in the
  # fuzzy-finder
  PALETTE_SNIPPET_COMMENT="    ## "

  # Main function of the widget
  _palette_widget() {
    # download "TLDR pages" if we don't have them
    if [[ ! -d "$PALETTE_TLDR_PAGES_DIR" ]]; then
      print -r
      _palette_download_tldr_pages
      print -r
    fi

    # try to fill in a placeholder if there're any, otherwise pick a snippet
    if ! _palette_fill_in_placeholder; then
      local selected
      if selected="$(_palette_parse_tldr_pages | fzf --ansi --tiebreak=begin,chunk)"
      then
        # paste selected snippet without its description
        zle -U "${selected%%$PALETTE_SNIPPET_COMMENT*}"
      fi
    fi

    # immediately redraw
    zle reset-prompt
  }

  # This function deletes the first placeholder from the buffer and places the
  # cursor at the beginning of that placeholder. If there're no placeholders in
  # the buffer, it exits with exit code 1.
  _palette_fill_in_placeholder() {
    # NOTE!!! indexes in ZSH arrays start at one!
    local start_index="${BUFFER[(i)$PALETTE_PLACEHOLDER_START]}"
    (( start_index == 0 || start_index > ${#BUFFER} )) && return 1
    local end_index="${BUFFER[(i)$PALETTE_PLACEHOLDER_END]}"
    # the CURSOR variable is zero-based while ZSH arrays are one-based
    (( CURSOR = start_index - 1 ))
    BUFFER="${BUFFER[1,start_index-1]}${BUFFER[end_index+2,${#BUFFER}]}"
  }

  # This function parses "TLDR pages" for snippets using AWK. Fortunately, all
  # "TLDR pages" files use the same Markdown-like syntax so they're very easy
  # to parse.
  _palette_parse_tldr_pages() {
    # I chose to use AWK here because it was designed specifically for text
    # processing and includes all the basic utilities that I need here. The
    # backslash after the argument to find(1) is necessary so that it still
    # searches the directory if it is symlinked.
    find "$PALETTE_TLDR_PAGES_DIR/" -type f -name '*.md' -exec awk '
      # when we find a "description" line...
      match($0, /^- (.+):$/, match_groups) {
        # ...get actual description from it...
        description = match_groups[1]
        # ...then skip any lines that are not actual commands, while saving RegEx
        # match groups...
        while (!match($0, /^`(.+)`$/, match_groups)) getline
        # ...after that we can get the command...
        command = match_groups[1]
        # ...and finally, we print command and description, separated by
        # PALETTE_SNIPPET_COMMENT, and with some colors!
        printf "%s\x1b[90m'"$PALETTE_SNIPPET_COMMENT"'%s\x1b[0m\n", command, description
      }
    ' {} +
  }

  # This function downloads the "TLDR pages"
  _palette_download_tldr_pages() {
    mkdir -pv -- "$PALETTE_TLDR_PAGES_DIR"
    print -r -- "Downloading tldr pages..."

    if curl -Lf https://github.com/tldr-pages/tldr/archive/refs/heads/main.tar.gz |
      tar -C "$PALETTE_TLDR_PAGES_DIR" --gzip --strip-components 2 --no-same-owner --extract tldr-main/pages
    then
      print -r -- "Done!"
    else
      rmdir -v -- "$PALETTE_TLDR_PAGES_DIR"
    fi
  }

  # finally, bind the widget to Alt+Shift+P (or Esc+Shift+P)
  zle -N _palette_widget
  bindkey '\eP' _palette_widget
# }}}

# find man page widget {{{
  _find_man_page_widget() {
    setopt local_options extended_glob
    local words=("${(@z)BUFFER}")

    local reply=("${words[@]}")
    if _alias_tips_expand_aliases; then
      words=("${reply[@]}")
    fi
    unset reply

    local -A command_manpage_name_overrides=(
      [hub]=git
      [systemctl]=systemd
    )

    local -a precommands=(
      noglob nocorrect exec command builtin nohup disown sudo time gtime prime-run allow-ptrace
    )

    local -a commands_with_subcommands=(
      git hub gh npm apt docker pip perf kitten systemctl
    )

    local cmd_name arg is_subcommand=0
    for arg in "${words[@]}"; do
      # Skip flags and variable assignments
      if [[ "$arg" == '-'* || "$arg" == ([[:IDENT:]]##)=* ]]; then
        continue
      fi

      # Skip command prefixes
      if (( ! is_subcommand )) && contains precommands "$arg"; then
        continue
      fi

      if (( ! is_subcommand )); then
        cmd_name="${command_manpage_name_overrides[$arg]-$arg}"
      else
        cmd_name="${cmd_name}-${arg}"
      fi

      if (( ! is_subcommand )) && contains commands_with_subcommands "$arg"; then
        is_subcommand=1
        continue
      fi

      break
    done

    local manpage
    if manpage="$(fzf-man "$cmd_name")"; then
      zle push-line
      BUFFER="man $manpage"
      zle reset-prompt
      zle accept-line
    else
      zle reset-prompt
    fi
  }
  zle -N _find_man_page_widget
  # bind to F1
  bindkey '\eOP' _find_man_page_widget
# }}}

# other keybindings {{{

  autoload -Uz edit-command-line
  if [[ $EDITOR == *vim ]]; then
    zstyle ':zle:edit-command-line' editor ${=EDITOR} -c 'set ft=zsh wrap'
  fi
  bindkey '\ee' edit-command-line

  bindkey '\eu' undo
  bindkey '\eU' redo

  _zle_lfcd() {
    lfcd
    zle reset-prompt
  }

  zle -N _zle_lfcd
  bindkey '\eo' _zle_lfcd

# }}}
