if [[ -n "$LS_COLORS" ]]; then
  zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
fi
