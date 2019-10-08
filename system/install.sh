#!/bin/sh

set -eu

distro="$(lsb_release -si)"
case "$distro" in
  Arch)
    cd arch
    makepkg --syncdeps --force --install
    ;;
  *)
    echo >&2 "distro '$distro' is unsupported"
    exit 1
    ;;
esac
