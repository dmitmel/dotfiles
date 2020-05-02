#!/bin/sh

# currently supports only Firefox
# folder support would be nice, though I doubt it is really useful
# NOTE: doesn't support multiple Firefox profiles

set -eu

script_dir="$(dirname "$0")"

# POSIX sh doesn't have arrays, so I have to make do with loops
for db_file in ~/.mozilla/firefox/*/weave/bookmarks.sqlite; do
  if [ ! -e "$db_file" ]; then exit 1; fi

  # Firefox holds a lock over the database file, so I can't connect to it even
  # in the readonly mode: https://stackoverflow.com/a/7857866/12005228
  # as a workaround I copy the file

  db_copy_file=$(mktemp -t "query-bookmarks.XXXXXXXXXX.sqlite")
  delete_db_copy_file() {
    rm -rf "$db_copy_file"
  }
  trap delete_db_copy_file EXIT

  cp -f "$db_file" "$db_copy_file"

  if url="$(python "$script_dir/../script-resources/query-bookmarks.py" "$db_copy_file" | rofi -dmenu -i -p "bookmark")"; then
    # dummy printf is used to remove the trailing newline produced by rofi: https://stackoverflow.com/a/12524345/12005228
    printf "%s" "$(echo "$url" | cut -f2-)" | xsel --clipboard --input
    notify-send --icon=utilities-terminal --expire-time=2500 "$0" "bookmark link copied to clipboard!"
  fi

  exit 0
done
