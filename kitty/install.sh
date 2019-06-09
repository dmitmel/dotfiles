#!/usr/bin/env bash

set -e
shopt -s nullglob

cd "$(dirname "$0")"

ansi_reset="$(tput sgr0)"
ansi_bold="$(tput bold)"
ansi_rev="$(tput rev)"
log() {
  echo >&2 "${ansi_bold}${ansi_rev}[$0]${ansi_reset}" "$@"
}

mkdir -p src
cd src

log "fetching release information"
eval "$(
  curl --show-error --fail https://api.github.com/repos/kovidgoyal/kitty/releases/latest |
  jq --raw-output '
    "release_version=" + (.name | sub("^version "; "") | @sh) + "\n" + (
      .assets | map(select(.label == "Source code")) | first |
      "release_src_filename=" + (.name                 | @sh) + "\n" +
      "release_src_url="      + (.browser_download_url | @sh)
    )
  '
)"
if [ -z "$release_version" ]; then
  log "couldn't parse response from GitHub API"
  exit 1
fi
log "the latest version is $release_version"

if [ ! -f "$release_src_filename" ]; then
  log "downloading $release_src_filename from $release_src_url"
  curl --show-error --fail --location "$release_src_url" -o "$release_src_filename"
else
  log "$release_src_filename had already downloaded"
fi

release_src_dir="${release_src_filename%.tar.xz}"
if [ -d "$release_src_dir" ]; then
  log "clearing previous source code directory"
  rm -r "$release_src_dir"
fi

log "unpacking source code archive to src/$release_src_dir"
tar --xz -xf "$release_src_filename"
cd "$release_src_dir"

log "patching"
for patch in ../../patches/*.patch; do
  log "applying patch $patch"
  patch --unified --strip 0 < "$patch"
done

log "compiling"
case "$OSTYPE" in
  darwin*) make app ;;
   linux*) python3 setup.py linux-package ;;
        *) log "error: compilation on $OSTYPE is not supported"; exit 1 ;;
esac
