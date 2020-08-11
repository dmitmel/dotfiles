#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=/dev/null
source ~/.config/copy-crosscode-emoji-url.conf.sh

data_refs=()
data_urls=()
data_titles=()

read_line() {
  IFS= read -r "$@"
}

# https://stackoverflow.com/a/15692004/12005228
print_lines() {
  eval "printf '%s\n' \"\${$1[@]}\""
}

while read_line ref && read_line url && read_line title; do
  data_refs+=("$ref")
  data_urls+=("$url")
  data_titles+=("$title")
done < <(
  curl --location --fail --max-time 10 "$CCBOT_EMOTE_REGISTRY_DUMP_URL" |
  jq -r '.list[] | select(.safe) | .ref, .url, "\(.ref) [\(.guild_name)]"'
)

if index="$(print_lines data_titles | rofi -dmenu -i -p cc-emoji -format i)"; then
  echo -n "${data_urls[$index]}" | xsel --clipboard --input
  notify-send --icon=utilities-terminal --expire-time=3000 "$0" "copied URL of ${data_refs[$index]} to clipboard!"
fi
