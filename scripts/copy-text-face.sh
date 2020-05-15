#!/usr/bin/env bash

declare -A faces=(
  ["shrug face"]=$'\xc2\xaf\\_(\xe3\x83\x84)_/\xc2\xaf'
  ["lenny face"]=$'( \xcd\xa1\xc2\xb0 \xcd\x9c\xca\x96 \xcd\xa1\xc2\xb0)'
  ["table flip"]=$'(\xe3\x83\x8e\xe0\xb2\xa0\xe7\x9b\x8a\xe0\xb2\xa0)\xe3\x83\x8e\xe5\xbd\xa1\xe2\x94\xbb\xe2\x94\x81\xe2\x94\xbb'
)

if IFS=$'\n' face_name="$(echo -E "${!faces[*]}" | rofi -dmenu -i)"; then
  face="${faces[$face_name]}"
  echo -n "$face" | xsel --clipboard --input
  notify-send --icon=utilities-terminal --expire-time=2500 "$0" "$face_name copied to clipboard"
fi
