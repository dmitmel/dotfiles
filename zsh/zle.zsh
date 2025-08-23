#!/usr/bin/env zsh

# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Builtins
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Standard-Widgets

# _fzf_history_widget {{{
  # taken from https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh
  _fzf_history_widget() {
    local selected
    if selected=( $(fc -rl 1 | fzf --nth=2.. --scheme=history --query="$LBUFFER") ); then
      zle vi-fetch-history -n "${selected[1]}"
    fi
    zle reset-prompt
  }

  zle -N _fzf_history_widget
  bindkey '\er' _fzf_history_widget
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
      if selected="$(_palette_parse_tldr_pages | fzf --ansi)"
      then
        # paste selected snippet without its description
        zle -U "${selected%%$PALETTE_SNIPPET_COMMENT*}"
      fi
    fi

    # immediately redraw
    zle redisplay
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
  # "TLDR pages" files are use the same Markdown-like syntax so they're very easy
  # to parse.
  _palette_parse_tldr_pages() {
    # I chose to use AWK here because it was designed specifically for text
    # processing and includes all basic utilities that I need here.
    awk '
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
    ' "$PALETTE_TLDR_PAGES_DIR"/**/*.md
  }

  # This function downloads the "TLDR pages"
  _palette_download_tldr_pages() {
    mkdir -pv "$PALETTE_TLDR_PAGES_DIR"
    print -r -- "Downloading tldr pages..."

    if curl -Lf https://github.com/tldr-pages/tldr/archive/master.tar.gz |
      tar -C "$PALETTE_TLDR_PAGES_DIR" --gzip --strip-components 2 --extract tldr-master/pages
    then
      print -r -- "Done!"
    fi
  }

  # finally, bind the widget to Alt+Shift+P (or Esc+Shift+P)
  zle -N _palette_widget
  bindkey '\eP' _palette_widget
# }}}

# expand-or-complete-with-dots {{{
  # expand-or-complete-with-dots() {
  #   local wrap_ctrl_supported
  #   if (( ${+terminfo[rmam]} && ${+terminfo[smam]} )); then
  #     wrap_ctrl_supported=1
  #   fi
  #   # toggle line-wrapping off and back on again
  #   if [[ -n "$wrap_ctrl_supported" ]]; then echoti rmam; fi
  #   print -Pn "%F{red}...%f"
  #   if [[ -n "$wrap_ctrl_supported" ]]; then echoti smam; fi
  #   zle expand-or-complete
  #   zle redisplay
  # }
  # zle -N expand-or-complete-with-dots
  # bindkey "^I" expand-or-complete-with-dots
# }}}

# find man page widget {{{
  _widget_find_man_page() {
    local words=("${(@z)BUFFER}")

    local reply=("${words[@]}")
    if _alias_tips_expand_aliases; then
      words=("${reply[@]}")
    fi
    unset reply

    local -A command_manpage_name_overrides=(
      [hub]=git
    )

    local cmd_name arg i is_subcommand
    for (( i = 1; i <= ${#words}; i++ )); do
      arg="${words[$i]}"

      # Skip flags
      if [[ "$arg" == '-'* ]]; then
        continue
      fi

      # Skip command prefixes
      if [[ -z "$is_subcommand" && "$arg" == (noglob|nocorrect|exec|command|builtin|nohup|disown|sudo|time|gtime|prime-run) ]]; then
        continue
      fi

      if [[ -z "$is_subcommand" ]]; then
        cmd_name="${command_manpage_name_overrides[$arg]-$arg}"
      else
        cmd_name="${cmd_name}-${arg}"
      fi

      if [[ -z "$is_subcommand" && "$arg" == (git|hub|gh|npm|apt|docker|pip|perf) ]]; then
        is_subcommand=1
        continue
      fi

      break
    done

    local manpage
    if manpage="$(fzf-man "$cmd_name")"; then
      zle push-line
      BUFFER="man $manpage"
      zle redisplay
      zle accept-line
    else
      zle redisplay
    fi
  }
  zle -N find-man-page _widget_find_man_page
  # bind to F1
  bindkey '\eOP' find-man-page
# }}}

# other keybindings {{{

  bindkey '\ee' edit-command-line
  bindkey '\eu' undo
  bindkey '\eU' redo

# }}}
