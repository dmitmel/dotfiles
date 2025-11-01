# My re-implementation of the excellent alias-tips plugin:
# <https://github.com/djui/alias-tips/blob/45e4e97ba4ec30c7e23296a75427964fc27fb029/alias-tips.plugin.zsh>
# <https://github.com/djui/alias-tips/blob/45e4e97ba4ec30c7e23296a75427964fc27fb029/alias-tips.py>
# The point is that it is written in pure shellscript unlike the original, so
# doesn't rely on starting a Python subprocess on every entered command.
#
# This plugin should assist in remembering aliases! Only prefix aliases are
# supported, though (as opposed to suffix and global ones). Don't worry, the
# other aliases are really uncommon, and my config currently includes zero of
# those.

autoload -Uz add-zsh-hook && add-zsh-hook preexec _preexec_alias_tips

# Paradoxically, this function, written in possibly the slowest programming
# language on the planet (assuming that this atrocity deserves to be called a
# "programming language", but that is beside the point), still beats the Python
# implementation by at least a factor of two. Why? Subprocess spawn costs.
# Also, we have direct access to the `$aliases` hashtable, so we can avoid
# performing janky parsing of `alias` and `functions` output that the original
# has to do, plus we also have access to Zsh's word parser, which, in theory,
# will help us generate even higher-quality alias tips.
_preexec_alias_tips() {
  setopt local_options err_return

  local orig_cmd="$1"
  local cmd_words=("${(@z)orig_cmd}")

  # Skip empty commands (they break our algorithms).
  if (( ! ${#cmd_words[@]} )); then
    return
  fi

  # Aliases are sorted by the so-called "lexed length" - basically, the sum of
  # lengths of all parsed words, plus 1 for every imaginary typed whitespace.
  # This should also help us improve the quality of tips compared to dumb
  # string length comparisons.
  local -i orig_lexed_len=0 min_lexed_len=-1
  local min_short_cmd=''
  local word; for word in "${cmd_words[@]}"; do
    (( orig_lexed_len += ${#word} + 1 ))
  done; unset word

  # This routine repeatedly expands aliases in the original string. For
  # reference, further alias expansion is performed on the input so that we can
  # suggest further shortening of alises. For example, if we have two alises
  # defined: `alias gc='git commit'` and `alias gca='git commit --all'`, we
  # will be able to suggest to shorten `gc --all` to just `gca`.
  local reply=("${cmd_words[@]}")
  _alias_tips_expand_aliases
  cmd_words=("${reply[@]}")

  local alias_name alias_str; for alias_name alias_str in "${(@kv)aliases}"; do
    local alias_words=("${(@z)alias_str}")
    # When can an alias be empty? But anyway.
    if (( ! ${#alias_words[@]} )); then
      continue
    fi

    # The same alias expansion routine as before. Aliases can also reference
    # other aliases!
    local reply=("${alias_words[@]}")
    _alias_tips_expand_aliases
    alias_words=("${reply[@]}")

    # Okay, now that we have normalized both the original command and the
    # current alias to their fully expanded forms, we check if the alias is
    # applicable. That is, if the command starts with the current alias. First,
    # let's try checking the length. There is no way for the command to start
    # with the alias if the command is shorter!
    if (( ${#cmd_words[@]} < ${#alias_words[@]} )); then
      continue
    fi
    # Now, the classic algorithm.
    local -i idx=1
    for (( ; idx <= ${#alias_words[@]}; idx++ )); do
      if [[ "${cmd_words[$idx]}" != "${alias_words[$idx]}" ]]; then
        break
      fi
    done
    # We succeed if we have advanced past the length of the alias'es words.
    if (( idx <= ${#alias_words[@]} )); then
      continue
    fi

    # Compute the lexed length for the original command with an inserted alias.
    local short_cmd_words=("$alias_name" "${(@)cmd_words[idx,-1]}")
    local -i short_lexed_len=0
    local word; for word in "${short_cmd_words[@]}"; do
      (( short_lexed_len += ${#word} + 1 ))
    done; unset word

    # We loop through all aliases in search of the shortest expansion.
    if (( short_lexed_len > 0 && short_lexed_len < orig_lexed_len &&
      (min_lexed_len < 0 || short_lexed_len < min_lexed_len) )); then
      (( min_lexed_len = short_lexed_len ))
      # The commented-out code is an experimental nice substitution algorithm.
      # if [[ "${orig_cmd}" == "${alias_str} "* ]]; then
      #   min_short_cmd="${alias_name} ${orig_cmd[${#alias_str}+2,-1]}"
      # else
        min_short_cmd="${short_cmd_words[*]}"
      # fi
    fi
  done; unset alias_name alias_words

  # Finally...
  if (( min_lexed_len > 0 )); then
    print -r -- "${fg_no_bold[blue]}Alias tip: ${fg_bold[blue]}${min_short_cmd}${reset_color}"
  fi
}

# This routine repeatedly expands aliases in the original string. A hashtable
# is used to track the already expanded aliases, so that we don't end up
# running in circles on self-references (for example, `alias ls="ls -hF"`). For
# future reference, no quoting is necessary in array/hash subscripts (adding
# quotes actually changes the key). Input and result is supplied via the
# `reply` array.
_alias_tips_expand_aliases() {
  setopt local_options err_return
  local -A used_aliases=()
  while (( ${+aliases[${reply[1]}]} && ! ${+used_aliases[${reply[1]}]} )); do
    used_aliases[${reply[1]}]=1
    reply=("${(@z)${aliases[${reply[1]}]}}" "${(@)reply[2,-1]}")
  done
}
